import Foundation

func se_initialize_client() -> Int32 {
    print("se_initialize_client called")
    return 0
}

func se_connect_to_server(_ host: UnsafePointer<CChar>, _ port: Int32) -> Int32 {
    print("se_connect_to_server called: \(String(cString: host)):\(port)")
    return 0
}

func se_send_hello() -> Int32 {
    print("se_send_hello called")
    return 0
}

func se_receive_hello() -> Int32 {
    print("se_receive_hello called")
    return 0
}

func se_authenticate_client(_ username: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>) -> Int32 {
    print("se_authenticate_client called: \(String(cString: username))")
    return 0
}

func se_get_redirect_server(_ hostbuf: UnsafeMutablePointer<CChar>, _ bufsize: Int32, _ port: UnsafeMutablePointer<Int32>) -> Int32 {
    let server = "redirect.server.example"
    strncpy(hostbuf, server, Int(bufsize))
    port.pointee = 443
    print("se_get_redirect_server called, returning \(server):\(port.pointee)")
    return 0
}

func se_establish_tunnel(_ tunnelIndex: Int) -> Int32 {
    print("se_establish_tunnel called: Tunnel \(tunnelIndex)")
    return 0
}

func se_dhcp_discover() -> Int32 {
    print("se_dhcp_discover called")
    return 0
}

func se_dhcp_receive_offer() -> Int32 {
    print("se_dhcp_receive_offer called")
    return 0
}
