//
//  IPerfFullAppView.swift
//  iperf
//
//  Created by jake on 5/7/26.
//

import SwiftUI
import Charts

struct IPerfFullAppView: View {
    @StateObject var viewModel = IPerfAppViewModel()
    
    var body: some View {
      NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
              VStack(spacing: 0) {
                
                // 1. TOP METRICS HEADER (Visible when running)
                if viewModel.isRunning || !viewModel.dataPoints.isEmpty {
                  
                  VStack(spacing: 12) { // Main vertical stack for rows
                    
                    // --- ROW 1: Universal Metrics (Always visible) ---
                    HStack(spacing: 12) {
                      DashboardMetricCard(
                        title: "BANDWIDTH",
                        value: String(format: "%.1f", viewModel.averageBandwidth),
                        unit: "Mbps",
                        color: .blue
                      )
                      
                      DashboardMetricCard(
                        title: "LATENCY",
                        value: String(format: "%.0f", viewModel.averageLatency),
                        unit: "ms",
                        color: .green
                      )
                    }
                    
                    // --- ROW 2: Protocol-Specific Metrics ---
                    
                    // 2A. UDP Row
                    if viewModel.protocolMode == 1 {
                      HStack(spacing: 12) {
                        DashboardMetricCard(
                          title: "LOSS",
                          value: String(format: "%.1f", viewModel.averagePacketLoss),
                          unit: "%",
                          color: viewModel.averagePacketLoss > 0 ? .red : .primary
                        )
                        
                        DashboardMetricCard(
                          title: "JITTER",
                          value: String(format: "%.1f", viewModel.averageJitter),
                          unit: "ms",
                          color: viewModel.averageJitter > 30 ? .orange : .primary
                        )
                      }
                    }
                    // 2B. TCP Upload Row (Commented out for now)
                    // else if viewModel.protocolMode == 0 && viewModel.transmitMode == 0 {
                    //     HStack(spacing: 12) {
                    //         DashboardMetricCard(
                    //             title: "RETRANSMITS",
                    //             value: "\(viewModel.totalRetransmits)",
                    //             unit: "pkts",
                    //             color: viewModel.totalRetransmits > 10 ? .red : .primary
                    //         )
                    //
                    //         // Invisible spacer card so the Retransmits card stays
                    //         // the exact same size as the others and doesn't stretch across the screen
                    //         Color.clear
                    //             .frame(maxWidth: .infinity)
                    //     }
                    // }
                  }
                  .padding()
                  .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 2. MAIN CONTENT AREA
                ScrollView {
                  VStack(spacing: 20) {
                    
                    // PROGRESS BAR
                    if viewModel.isRunning {
                      ProgressView(value: viewModel.progress)
                        .tint(.blue)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    }
                    
                    // SETTINGS SECTION (Collapsible)
                    if !viewModel.isRunning {
                      settingsForm
                        .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
                    }
                    
                    // CHARTS SECTION
                    if !viewModel.dataPoints.isEmpty || !viewModel.latencyData.isEmpty {
                      chartHistory
                    } else if !viewModel.isRunning {
                      // Welcome / Empty State
                      ContentUnavailableView("Ready to Test", systemImage: "network", description: Text("Enter a server address and tap Start to measure performance."))
                        .padding(.top, 40)
                    }
                  }
                  .padding(.bottom, 100) // Space for the floating button
                }
              }
            }
            .navigationTitle("iPerf Pro")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isRunning ? "Stop" : "Start") {
                        viewModel.isRunning ? viewModel.stopTest() : viewModel.startTest()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.isRunning ? .red : .blue)
                }
            }
        }
    }
    
    // MARK: - Sub-components
    
    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // --- CONFIGURATION HEADER ---
            Text("CONFIGURATION")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.leading)
            
            VStack(spacing: 0) {
                settingRow(title: "Server", placeholder: "192.168.1.1", text: $viewModel.hostname)
                Divider().padding(.leading)
                settingRow(title: "Port", placeholder: "5201", text: $viewModel.port)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal)
            
            // --- TEST PARAMETERS HEADER ---
            Text("TEST PARAMETERS")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.leading)
                .padding(.top, 10)
            
            // 1. The Picker Box
            VStack(spacing: 0) { // <- This is the wrapper you were missing!
                Picker("Direction", selection: $viewModel.transmitMode) {
                    Text("Upload").tag(0)
                    Text("Download").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                Picker("Protocol", selection: $viewModel.protocolMode) {
                    Text("TCP").tag(0)
                    Text("UDP").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewModel.protocolMode == 1 {
                    Divider()
                    settingRow(title: "Target (bps)", placeholder: "1000000", text: $viewModel.targetBitrate)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal)
            
            // 2. The Slider/Duration Box
            VStack(spacing: 0) {
                Stepper("Parallel Streams: \(viewModel.streams)", value: $viewModel.streams, in: 1...16)
                    .font(.subheadline)
                    .padding()
                
                Divider()
                
                Picker("Duration", selection: $viewModel.durationIndex) {
                    Text("10s").tag(0)
                    Text("30s").tag(1)
                    Text("5m").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal)
        }
    }
    
    private var chartHistory: some View {
        VStack(spacing: 20) {
            PerformanceChart(title: "Throughput", data: viewModel.dataPoints, color: .blue, unit: "Mbps") { $0.bandwidth }
            PerformanceChart(title: "Latency", data: viewModel.latencyData, color: .orange, unit: "ms") { $0.latency }
            
            if viewModel.protocolMode == 1 {
                PerformanceChart(title: "Packet Loss", data: viewModel.packetLossData, color: .red, unit: "%", isBar: true) { $0.loss }
            }
        }
        .padding(.horizontal)
    } // <- This is the bracket that was missing!
    
    private func settingRow(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(title).font(.subheadline).frame(width: 80, alignment: .leading)
            TextField(placeholder, text: text)
                .keyboardType(title == "Port" ? .numberPad : .decimalPad)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}
