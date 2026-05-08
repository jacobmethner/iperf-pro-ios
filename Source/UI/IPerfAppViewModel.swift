//
//  IPerfAppViewModel.swift
//  iperf
//
//  Created by jake on 5/7/26.
//
import Network

@MainActor
class IPerfAppViewModel: ObservableObject {
    // UI State
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var hostname = UserDefaults.standard.string(forKey: "IPFHost") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "IPFPort") ?? "5201"
    @Published var transmitMode = 0
    @Published var streams = 1
    @Published var durationIndex = 0
    @Published var protocolMode = 0 // 0 = TCP, 1 = UDP
    @Published var targetBitrate = "1000000" // Default to 1,000,000 bps
    
    // Data Tracks
    @Published var dataPoints: [BandwidthDataPoint] = []
    @Published var latencyData: [LatencyDataPoint] = []
    @Published var packetLossData: [PacketLossDataPoint] = []
    @Published var jitterData: [Double] = []

    
    
    private var testRunner: IPFTestRunner?
    private var testStartTime: Date?

    // Computed latest values
    var latestBandwidth: String { String(format: "%.0f", dataPoints.last?.bandwidth ?? 0) }
    var latestLatency: String { String(format: "%.0f", latencyData.last?.latency ?? 0) }
    var latestLoss: String { String(format: "%.1f", packetLossData.last?.loss ?? 0) }
    var averagePacketLoss: Double {
      return packetLossData.last?.loss ?? 0.0
    }
    // Safely average all the 1-second jitter intervals
  var averageJitter: Double {
      guard !jitterData.isEmpty else { return 0.0 }
      let sum = jitterData.reduce(0, +)
      return sum / Double(jitterData.count)
    }
  
  // Safely average all the 1-second bandwidth intervals
      var averageBandwidth: Double {
          guard !dataPoints.isEmpty else { return 0.0 }
          // reduce(0) starts at 0, then adds the 'bandwidth' value of each point in the array
          let sum = dataPoints.reduce(0) { $0 + $1.bandwidth }
          return sum / Double(dataPoints.count)
      }
      
      // Safely average all the latency probes
      var averageLatency: Double {
          guard !latencyData.isEmpty else { return 0.0 }
          // reduce(0) starts at 0, then adds the 'latency' value of each point in the array
          let sum = latencyData.reduce(0) { $0 + $1.latency }
          return sum / Double(latencyData.count)
      }
  func startTest() {
    let durations: [UInt] = [10, 30, 300]
        let testDirection: IPFTestRunnerConfigurationType = (transmitMode == 0) ? .upload : .download
        let testProtocol: IPFTestRunnerProtocol = protocolMode == 0 ? .TCP : .UDP
        
        // 1. Use 'guard let' to safely unwrap the Objective-C object
        guard let config = IPFTestRunnerConfiguration(
            hostname: hostname,
            port: UInt(port) ?? 5201,
            duration: durations[durationIndex],
            streams: UInt(streams),
            type: testDirection,
            protocol: testProtocol
        ) else {
            print("Error: Could not initialize test configuration.")
            return
        }
        
        // 2. Now 'config' is guaranteed to exist, so you can access its properties safely!
        if config.protocol == .UDP {
            config.targetBitrate = UInt64(targetBitrate) ?? 1_000_000
        }
        
        testRunner = IPFTestRunner(configuration: config)
        dataPoints.removeAll()
        latencyData.removeAll()
        packetLossData.removeAll()
        jitterData.removeAll()
        testStartTime = Date()
        isRunning = true
        
        startLatencyProbes()
    
        testRunner?.startTest { [weak self] status in
          Task { @MainActor in
                guard let self = self else { return }
                
              if !status.running.boolValue {
                    self.finalizeTest()
                } else {
                    let elapsed = Date().timeIntervalSince(self.testStartTime ?? Date())
                    
                    // Update Bandwidth
                    self.dataPoints.append(BandwidthDataPoint(timeElapsed: elapsed, bandwidth: Double(status.bandwidth)))
                  if self.protocolMode == 1 {
                    // Update Packet Loss
                    self.packetLossData.append(PacketLossDataPoint(timeElapsed: elapsed, loss: Double(status.packetLossPercent)))
                    // Update Jitter
                    self.jitterData.append(status.jitter)
                  }
                    
                    self.progress = Double(status.progress)
                    

                }
            }
        }
    }
  private func measureNWLatency() {
      guard let portUI = UInt16(port) else { return }
      let host = NWEndpoint.Host(hostname)
      let port = NWEndpoint.Port(integerLiteral: 80)
      
      // 1. Snapshot the time LOCALLY while we are still on the Main Actor
      let localTestStartTime = self.testStartTime ?? Date()
      
      let connection = NWConnection(host: host, port: port, using: .tcp)
      let probeStartTime = CFAbsoluteTimeGetCurrent()
      
      connection.stateUpdateHandler = { [weak self] state in
          switch state {
          case .ready:
              let duration = (CFAbsoluteTimeGetCurrent() - probeStartTime) * 1000 // Convert to ms
              connection.cancel() // Close connection immediately
              
              // 2. Jump BACK to the Main Actor to safely update the UI variables
              Task { @MainActor in
                  guard let self = self else { return }
                  
                  // 3. Use the snapshot (localTestStartTime), NOT self.testStartTime
                  let elapsed = Date().timeIntervalSince(localTestStartTime)
                  self.latencyData.append(LatencyDataPoint(timeElapsed: elapsed, latency: duration))
              }
              
          case .failed, .cancelled:
              break
          default:
              break
          }
      }
      
      connection.start(queue: .global(qos: .userInitiated))
  }
    func stopTest() {
        testRunner?.stopTest()
        finalizeTest()
    }

    private func finalizeTest() {
        isRunning = false
        testRunner = nil
    }
    
    private func startLatencyProbes() {
      Task {
          while isRunning {
              measureNWLatency()
              try? await Task.sleep(nanoseconds: 1_000_000_000) // Sleep for 1 second
          }
      }
    }
}
