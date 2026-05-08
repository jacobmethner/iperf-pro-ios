
import SwiftUI
import Charts

struct IPFPerformanceDashboard: View {
    @ObservedObject var viewModel: ChartViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // --- 1. HEADER METRICS ---
                HStack(spacing: 12) {
                    DashboardMetricCard(title: "BANDWIDTH", value: viewModel.latestBandwidth, unit: "Mbps", color: .blue)
                    DashboardMetricCard(title: "LATENCY", value: viewModel.latestLatency, unit: "ms", color: .orange)
//                    DashboardMetricCard(title: "LOSS", value: viewModel.latestLoss, unit: "%", color: .red)
                }
                .padding(.horizontal)
                
                // --- 2. PERFORMANCE CHARTS ---
                VStack(spacing: 20) {
                    PerformanceChart(title: "Throughput", data: viewModel.dataPoints, color: .blue, unit: "Mbps") { $0.bandwidth }
                    PerformanceChart(title: "Latency (RTT)", data: viewModel.latencyData, color: .orange, unit: "ms") { $0.latency }
//                    PerformanceChart(title: "Packet Loss", data: viewModel.packetLossData, color: .red, unit: "%", isBar: true) { $0.loss }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Subviews

struct DashboardMetricCard: View {
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
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct PerformanceChart<T: Identifiable & TimeTrackable>: View {
    let title: String
    let data: [T]
    let color: Color
    let unit: String
    var isBar: Bool = false
    let valueProvider: (T) -> Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Chart(data) { point in
                if isBar {
                    BarMark(
                        x: .value("Time", point.timeElapsed),
                        y: .value(unit, valueProvider(point))
                    )
                    .foregroundStyle(color.gradient)
                } else {
                    LineMark(
                        x: .value("Time", point.timeElapsed),
                        y: .value(unit, valueProvider(point))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.gradient)
                    
                    AreaMark(
                        x: .value("Time", point.timeElapsed),
                        y: .value(unit, valueProvider(point))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.opacity(0.1).gradient)
                }
            }
            .frame(height: 140)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
}
