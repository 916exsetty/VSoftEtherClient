import networkextension

class packettunnelprovider: nepac​kettunnelprovider {
    override func starttunnel(options: [string : nsobject]?,
                              completionhandler: @escaping (error?) -> void) {
        dispatchqueue.global(qos: .background).async {
            self.updatestatus("initializing client")
            guard se_initialize_client() == 0 else {
                return completionhandler(nserror(domain: "softether", code: 1,
                        userinfokey: [nslocalizeddescriptionkey: "init failed"]))
            }

            self.updatestatus("connecting to cluster")
            "worxvpn.662.cloud".withcstring { host in
                if se_connect_to_server(host, 443) != 0 {
                    return completionhandler(nserror(domain: "softether", code: 2,
                        userinfokey: [nslocalizeddescriptionkey: "cluster connect failed"]))
                }
            }

            self.updatestatus("sending hello")
            guard se_send_hello() == 0 else {
                return completionhandler(nserror(domain: "softether", code: 3,
                        userinfokey: [nslocalizeddescriptionkey: "hello send failed"]))
            }

            self.updatestatus("receiving hello")
            guard se_receive_hello() == 0 else {
                return completionhandler(nserror(domain: "softether", code: 4,
                        userinfokey: [nslocalizeddescriptionkey: "hello receive failed"]))
            }

            self.updatestatus("authenticating user")
            "indteam2".withcstring { u in
                "{$password}".withcstring { p in
                    if se_authenticate_client(u, p) != 0 {
                        return completionhandler(nserror(domain: "softether", code: 5,
                            userinfokey: [nslocalizeddescriptionkey: "auth failed"]))
                    }
                }
            }

            self.updatestatus("getting redirect server")
            var hostbuf = [cstringrepeating: 0](count: 256)
            var port: int32 = 0
            guard se_get_redirect_server(&hostbuf, int32(hostbuf.count), &port) == 0 else {
                return completionhandler(nserror(domain: "softether", code: 6,
                        userinfokey: [nslocalizeddescriptionkey: "redirect failed"]))
            }
            let redirect = string(cstring: hostbuf)

            self.updatestatus("connecting to gateway \(redirect):\(port)")
            redirect.withcstring { h in
                if se_connect_to_server(h, Int(port)) != 0 {
                    return completionhandler(nserror(domain: "softether", code: 7,
                        userinfokey: [nslocalizeddescriptionkey: "gateway connect failed"]))
                }
            }

            for i in 0..<2 {
                self.updatestatus("establishing tunnel \(i+1)")
                guard se_establish_tunnel(i) == 0 else {
                    return completionhandler(nserror(domain: "softether", code: 8,
                            userinfokey: [nslocalizeddescriptionkey: "tunnel \(i+1) failed"]))
                }
            }

            self.updatestatus("sending dhcp discover")
            guard se_dhcp_discover() == 0 else {
                return completionhandler(nserror(domain: "softether", code: 9,
                        userinfokey: [nslocalizeddescriptionkey: "dhcp discover failed"]))
            }

            self.updatestatus("receiving dhcp offer")
            guard se_dhcp_receive_offer() == 0 else {
                return completionhandler(nserror(domain: "softether", code: 10,
                        userinfokey: [nslocalizeddescriptionkey: "dhcp offer failed"]))
            }

            self.updatestatus("tunnel up and running")
            completionhandler(nil)
        }
    }

    override func stoptunnel(with reason: neproviderstopreason,
                              completionhandler: @escaping () -> void) {
        // TODO: call c api to disconnect tunnels
        completionhandler()
    }

    func updatestatus(_ text: string) {
        let data = try? jsonserialization.data(withjsonobject: ["status": text], options: [])
        sendprovidermessage(data) { _ in }
    }
}