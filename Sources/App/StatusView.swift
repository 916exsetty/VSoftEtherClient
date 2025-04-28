// Sources/App/StatusView.swift
import SwiftUI

struct StatusView: View {
    @State private var statusMessages = ["Not connected"]
    
    var body: some View {
        VStack {
            ForEach(statusMessages, id: \.self) { message in
                HStack {
                    Circle()
                        .fill(message.contains("✅") ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(message)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("VPNStatus"))) { notification in
            if let message = notification.object as? String {
                statusMessages.append(message)
            }
        }
    }
}