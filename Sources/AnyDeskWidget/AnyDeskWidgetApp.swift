import AppKit
import SwiftUI

@main
struct AnyDeskWidgetApp: App {
    var body: some Scene {
        MenuBarExtra("AnyDesk Bağlan", systemImage: "rectangle.connected.to.line.below") {
            ConnectionView()
        }
        .menuBarExtraStyle(.window)
    }
}

private struct ConnectionView: View {
    @State private var address = ""
    @State private var message: String?
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "display")
                    .foregroundStyle(.secondary)

                Text("AnyDesk'e Bağlan")
                    .font(.headline)

                Spacer()
            }

            TextField("AnyDesk ID veya alias", text: $address)
                .textFieldStyle(.roundedBorder)
                .focused($isAddressFocused)
                .onSubmit(connect)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Çıkış") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")

                Spacer()

                Button("Bağlan", action: connect)
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear {
            message = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAddressFocused = true
            }
        }
    }

    private func connect() {
        message = nil

        var cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
            cleaned.removeAll(where: \Character.isWhitespace)
        }

        guard !cleaned.isEmpty else {
            message = "Bir AnyDesk ID veya alias girin."
            return
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "@._-"))
        guard cleaned.unicodeScalars.allSatisfy(allowed.contains),
              let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: "anydesk:\(encoded)") else {
            message = "Geçerli bir AnyDesk ID veya alias girin."
            return
        }

        guard NSWorkspace.shared.urlForApplication(toOpen: url) != nil else {
            message = "AnyDesk bulunamadı. Önce AnyDesk'i yükleyin."
            return
        }

        NSWorkspace.shared.open(url)
    }
}
