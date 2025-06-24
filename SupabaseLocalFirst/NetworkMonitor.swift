//
//  NetworkMonitor.swift
//  SupabaseLocalFirst
//
//  Created by Marcus Buexenstein on 6/24/25.
//

import SwiftUI
import Network

extension EnvironmentValues {
    @Entry var isNetworkConnected: Bool = true
    @Entry var connectionType: NWInterface.InterfaceType?
}

@Observable
class NetworkMonitor: ObservableObject {
    var isConnected: Bool
    var connectionType: NWInterface.InterfaceType?
    
    private var queue = DispatchQueue(label: "Monitor")
    private var monitor = NWPathMonitor()
    
    init() {
        self.isConnected = true
        startMonitor()
    }
    
    private func startMonitor() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                
                let types: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .loopback]
                if let type = types.first(where: { path.usesInterfaceType($0) }) {
                    self.connectionType = type
                } else {
                    self.connectionType = nil
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}
