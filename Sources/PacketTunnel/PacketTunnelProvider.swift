import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let username = "indteam2"
    let password = "whatever_password_they_gave"

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.updateStatus("initializing client")
            guard se_initialize_client() == 0 else {
                return completionHandler(NSError(domain: "softether", code: 1, userInfo: [NSLocalizedDescriptionKey: "init failed"]))
            }

            self.updateStatus("connecting to cluster")
            "worxvpn.662.cloud".withCString { host in
                if se_connect_to_server(host, 443) != 0 {
                    return completionHandler(NSError(domain: "softether", code: 2, userInfo: [NSLocalizedDescriptionKey: "cluster connect failed"]))
                }
            }

            self.updateStatus("sending hello")
            guard se_send_hello() == 0 else {
                return completionHandler(NSError(domain: "softether", code: 3, userInfo: [NSLocalizedDescriptionKey: "hello send failed"]))
            }

            self.updateStatus("receiving hello")
            guard se_receive_hello() == 0 else {
                return completionHandler(NSError(domain: "softether", code: 4, userInfo: [NSLocalizedDescriptionKey: "hello receive failed"]))
            }

            self.updateStatus("authenticating user")
            self.username.withCString { u in
                self.password.withCString { p in
                    if se_authenticate_client(u, p) != 0 {
                        return completionHandler(NSError(domain: "softether", code: 5, userInfo: [NSLocalizedDescriptionKey: "auth failed"]))
                    }
                }
            }

            self.updateStatus("getting redirect server")
            var hostbuf = [CChar](repeating: 0, count: 256)
            var port: Int32 = 0
            guard se_get_redirect_server(&hostbuf, Int32(hostbuf.count), &port) == 0 else {
                return completionHandler(NSError(domain: "softether", code: 6, userInfo: [NSLocalizedDescriptionKey: "redirect failed"]))
            }
            let redirect = String(cString: hostbuf)

            self.updateStatus("connecting to gateway \(redirect):\(port)")
            redirect.withCString { h in
                if se_connect_to_server(h, Int(port)) != 0 {
                    return completionHandler(NSError(domain: "softether", code: 7, userInfo: [NSLocalizedDescriptionKey: "gateway connect failed"]))
                }
            }

            for i in 0..<2 {
                self.updateStatus("establishing tunnel \(i+1)")
                guard se_establish_tunnel(i) == 0 else {
                    return completionHandler(NSError(domain: "softether", code: 8, userInfo: [NSLocalizedDescriptionKey: "tunnel \(i+1) failed"]))
                }
            }

            self.updateStatus("sending dhcp discover")
            guard se_dhcp_discover() == 0 else {
                return completionHandler(NSError(domain: "softether", code: 9, userInfo: [NSLocalizedDescriptionKey: "dhcp discover failed"]))
            }

            self.updateStatus("receiving dhcp offer")
            guard se_dhcp_receive_offer() == 0 else {
                return completionHandler(NSError(domain: "softether", code: 10, userInfo: [NSLocalizedDescriptionKey: "dhcp offer failed"]))
            }

            self.updateStatus("tunnel up and running")
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // TODO: call C api to disconnect tunnels
        completionHandler()
    }

    func updateStatus(_ text: String) {
        let data = try? JSONSerialization.data(withJSONObject: ["status": text], options: [])
        sendProviderMessage(data) { _ in }
    }
}
