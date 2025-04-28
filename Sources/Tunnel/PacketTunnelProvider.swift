// Sources/Tunnel/PacketTunnelProvider.swift
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    var currentConnection: NWConnection?
    var redirectHost: String?
    var redirectPort: Int?

private func startDHCPProcess() {
    Task {
        // 1. Request IP
        if let ipAddress = await DHCPManager.requestIPAddress(packetFlow: self.packetFlow) {
            log("Obtained IP: \(ipAddress) ✅")
            
            // 2. Update Network Settings
            let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "162.159.193.1")
            newSettings.ipv4Settings = NEIPv4Settings(
                addresses: [ipAddress],
                subnetMasks: ["255.255.255.0"]
            )
            
            // 3. Apply Settings
            try? await self.setTunnelNetworkSettings(newSettings)
        } else {
            log("DHCP Failed ❌")
        }
    }
}

    private func reconnectToRedirectedServer(host: String, port: Int) {
    // 1. Close Existing Connection
    softether_close_connection(vpnSession)
    
    // 2. Create New Configuration
    var newConfig = VPNConfig(
        server_host: host,
        server_port: Int32(port),
        username: VPNConfig.username,
        password: VPNConfig.password
    )
    
    // 3. Reinitialize
    vpnSession = softether_init_context()
    softether_configure(vpnSession, newConfig)
    
    // 4. Connect Again
    let connectResult = softether_connect(vpnSession)
    log("Reconnection result: \(connectResult == 1 ? "Success ✅" : "Failed ❌")")
    
    if connectResult == 1 {
        authenticateUser()
    }
}

    // MARK: - SoftEther Protocol Implementation
private func performSoftEtherHandshake() {
    // 1. Send HELLO
    let helloResult = softether_send_hello(vpnSession)
    log("Sent HELLO packet. Result: \(helloResult)")
    
    // 2. Receive Server Response
    receiveServerResponse { [weak self] response in
        guard let self else { return }
        
        // 3. Handle Redirect
        if response.hasPrefix("REDIRECT") {
            let parts = response.components(separatedBy: "|")
            let newHost = parts[1]
            let newPort = Int(parts[2]) ?? 443
            log("Redirected to \(newHost):\(newPort)")
            
            // 4. Reconnect to New Server
            self.reconnectToRedirectedServer(host: newHost, port: newPort)
        } else {
            // 5. Authenticate
            authenticateUser()
        }
    }
}

private func authenticateUser() {
    let authResult = softether_authenticate(vpnSession, VPNConfig.username, VPNConfig.password)
    log("Authentication result: \(authResult == 1 ? "Success ✅" : "Failed ❌")")
    
    if authResult == 1 {
        startDHCPProcess()
    }
}
    
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