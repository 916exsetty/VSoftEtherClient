// Sources/Tunnel/PacketTunnelProvider.swift
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    var currentConnection: NWConnection?
    var redirectHost: String?
    var redirectPort: Int?
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        // Phase 1: Connect to cluster
        try await connectToCluster()
        
        // Phase 2: Handle redirection
        guard let redirectHost = redirectHost, let redirectPort = redirectPort else {
            throw NSError(domain: "VPN", code: 1, userInfo: [NSLocalizedDescriptionKey: "No redirect received"])
        }
        
        // Phase 3: Establish dual connections
        let conn1 = try await createTCPConnection(host: redirectHost, port: redirectPort)
        let conn2 = try await createTCPConnection(host: redirectHost, port: redirectPort)
        
        // Phase 4: DHCP negotiation
        try await performDHCPExchange(connections: [conn1, conn2])
    }
    
    private func connectToCluster() async throws {
        let connection = NWConnection(
            host: VPNConfig.clusterHost,
            port: .init(integerLiteral: VPNConfig.primaryPort),
            using: .tls
        )
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.handleClusterResponse(connection)
            case .failed(let error):
                self?.log("Cluster connection failed: \(error)")
            default: break
            }
        }
        
        connection.start(queue: .main)
        currentConnection = connection
    }
    
    private func handleClusterResponse(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
            guard let data = data,
                  let response = String(data: data, encoding: .utf8) else { return }
            
            // Parse redirect from cluster (example format: "REDIRECT|77.48.2.5|992")
            let components = response.components(separatedBy: "|")
            if components[0] == "REDIRECT" && components.count == 3 {
                self?.redirectHost = components[1]
                self?.redirectPort = Int(components[2])
                self?.log("Received redirect to \(components[1]):\(components[2])")
            }
        }
    }
}