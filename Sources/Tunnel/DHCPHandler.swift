// Sources/Tunnel/DHCPHandler.swift
import NetworkExtension

class DHCPHandler {
    static func sendDiscover(packetFlow: NEPacketTunnelFlow) async -> Data? {
        // Build DHCP Discover packet (simplified)
        var discoverPacket = Data()
        discoverPacket.append(0x01) // Message type: Boot Request
        discoverPacket.append(0x01) // Hardware type: Ethernet
        discoverPacket.append(0x06) // Hardware address length
        discoverPacket.append(0x00) // Hops
        
        // Send through tunnel
        try? packetFlow.writePackets([discoverPacket], withProtocols: [AF_INET])
        
        // Wait for offer
        return await withCheckedContinuation { continuation in
            packetFlow.readPackets { packets, _ in
                continuation.resume(returning: packets.first)
            }
        }
    }
}