// Sources/App/CertificateManager.swift
import Security

class CertificateManager {
    static func validateServerCertificate(_ trust: SecTrust) -> Bool {
        guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0) else { return false }
        
        // Load pinned certificate from app bundle
        guard let certPath = Bundle.main.path(forResource: "server_pinned", ofType: "cer"),
              let pinnedCertData = try? Data(contentsOf: URL(fileURLWithPath: certPath)),
              let pinnedCert = SecCertificateCreateWithData(nil, pinnedCertData as CFData) else {
            return false
        }
        
        // Compare certificates
        let serverCertData = SecCertificateCopyData(serverCert) as Data
        let pinnedCertData = SecCertificateCopyData(pinnedCert) as Data
        
        return serverCertData == pinnedCertData
    }
}