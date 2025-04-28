import Foundation

// fake initialization
func se_initialize_client() -> Int32 {
    return 0
}

// fake connect to server
func se_connect_to_server(_ host: UnsafePointer<CChar>, _ port: Int32) -> Int32 {
    return 0
}

// fake send hello
func se_send_hello() -> Int32 {
    return 0
}

// fake receive hello
func se_receive_hello() -> Int32 {
    return 0
}

// fake authenticate user
func se_authenticate_client(_ username: UnsafePointer<CChar>, _ password: UnsafePointer<CChar>) -> Int32 {
    return 0
}

// fake get redirect server
func se_get_redirect_server(_ hostBuffer: UnsafeMutablePointer<CChar>, _ bufSize: Int32, _ port: UnsafeMutablePointer<Int32>) -> Int32 {
    let fakeHost = "redirectserver.worxvpn.662.cloud"
    strcpy(hostBuffer, fakeHost)
    port.pointee = 443
    return 0
}

// fake establish tunnel
func se_establish_tunnel(_ index: Int) -> Int32 {
    return 0
}

// fake dhcp discover
func se_dhcp_discover() -> Int32 {
    return 0
}

// fake dhcp receive offer
func se_dhcp_receive_offer() -> Int32 {
    return 0
}
