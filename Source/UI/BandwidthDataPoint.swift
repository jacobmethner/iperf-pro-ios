//
//  BandwidthDataPoint.swift
//  iperf
//
//  Created by jake on 5/6/26.
//


import SwiftUI
import Charts

// 1. The data point model
struct BandwidthDataPoint: Identifiable {
    let id = UUID()
    let timeElapsed: TimeInterval
    let bandwidth: Double
}

struct LatencyDataPoint: Identifiable {
    let id = UUID()
    let timeElapsed: TimeInterval
    let latency: Double
}

struct PacketLossDataPoint: Identifiable {
    let id = UUID()
    let timeElapsed: TimeInterval
    let loss: Double
}

// 2. The observable view model to drive UI updates
class ChartViewModel: ObservableObject {
      @Published var dataPoints: [BandwidthDataPoint] = []
      @Published var latencyData: [LatencyDataPoint] = []
//    @Published var packetLossData: [PacketLossDataPoint] = []
      
      // Computed properties for the cards
      var latestBandwidth: String { String(format: "%.0f", dataPoints.last?.bandwidth ?? 0) }
      var latestLatency: String { String(format: "%.0f", latencyData.last?.latency ?? 0) }
//      var latestLoss: String { String(format: "%.1f", packetLossData.last?.loss ?? 0) }
  
    func addDataPoint(bandwidth: Double, timeElapsed: TimeInterval) {
        dataPoints.append(BandwidthDataPoint(timeElapsed: timeElapsed, bandwidth: bandwidth))
        
        // Optional: Keep only the last 60 seconds of data to prevent memory bloat on long tests
        if dataPoints.count > 60 {
            dataPoints.removeFirst()
        }
    }
    func addLatencyPoint(latency: Double, timeElapsed: TimeInterval) {
        latencyData.append(LatencyDataPoint(timeElapsed: timeElapsed, latency: latency))
        if latencyData.count > 60 { latencyData.removeFirst() }
        }
    func clearData() {
        dataPoints.removeAll()
        latencyData.removeAll()
    }
}

// 3. The SwiftUI Chart View
struct BandwidthChartView: View {
    @ObservedObject var viewModel: ChartViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // --- 1. LIVE METRIC CARDS ---
                HStack(spacing: 12) {
                    MetricCard(title: "BANDWIDTH", value: viewModel.latestBandwidth, unit: "Mbps", color: .blue)
                    MetricCard(title: "LATENCY", value: viewModel.latestLatency, unit: "ms", color: .orange)
//                    MetricCard(title: "LOSS", value: viewModel.latestLoss, unit: "%", color: .red)
                }
                .padding(.horizontal)
                
                // --- 2. THE CHARTS ---
                VStack(spacing: 30) {
                    ChartSection(title: "Download Speed", data: viewModel.dataPoints, color: .blue, unit: "Mbps") { point in
                        point.bandwidth
                    }
                    
                    ChartSection(title: "Network Latency", data: viewModel.latencyData, color: .orange, unit: "ms") { point in
                        point.latency
                    }
                    
//                    ChartSection(title: "Packet Loss", data: viewModel.packetLossData, color: .red, unit: "%", isBar: true) { point in
//                        point.loss
//                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - UI Components

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ChartSection<T: Identifiable>: View {
    let title: String
    let data: [T]
    let color: Color
    let unit: String
    var isBar: Bool = false
    let valueProvider: (T) -> Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Chart(data) { point in
                if isBar {
                    BarMark(
                        x: .value("Time", (point as? any TimeTrackable)?.timeElapsed ?? 0),
                        y: .value(unit, valueProvider(point))
                    )
                    .foregroundStyle(color.gradient)
                } else {
                    LineMark(
                        x: .value("Time", (point as? any TimeTrackable)?.timeElapsed ?? 0),
                        y: .value(unit, valueProvider(point))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.gradient)
                    
                    AreaMark(
                        x: .value("Time", (point as? any TimeTrackable)?.timeElapsed ?? 0),
                        y: .value(unit, valueProvider(point))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.opacity(0.1).gradient)
                }
            }
            .frame(height: 150)
            .chartXAxis(.hidden) // Cleaner look for history
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// Protocol to help the generic chart find timeElapsed
protocol TimeTrackable {
    var timeElapsed: TimeInterval { get }
}
extension BandwidthDataPoint: TimeTrackable {}
extension LatencyDataPoint: TimeTrackable {}
extension PacketLossDataPoint: TimeTrackable {}
