import AppKit
import SwiftUI

@main
struct AnyDeskWidgetApp: App {
    var body: some Scene {
        MenuBarExtra(Copy.menuTitle, systemImage: "rectangle.connected.to.line.below") {
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

                Text(Copy.heading)
                    .font(.headline)

                Spacer()
            }

            TextField(Copy.placeholder, text: $address)
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
                Button(Copy.quit) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")

                Spacer()

                Button(Copy.connect, action: connect)
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
            message = Copy.emptyAddress
            return
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "@._-"))
        guard cleaned.unicodeScalars.allSatisfy(allowed.contains),
              let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: allowed),
              let url = URL(string: "anydesk:\(encoded)") else {
            message = Copy.invalidAddress
            return
        }

        guard NSWorkspace.shared.urlForApplication(toOpen: url) != nil else {
            message = Copy.anyDeskMissing
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private enum Copy {
    private static let language: String = {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("tr") { return "tr" }
        if preferred.hasPrefix("fr") { return "fr" }
        if preferred.hasPrefix("it") { return "it" }
        return "en"
    }()

    static var menuTitle: String { value(tr: "AnyDesk Bağlan", en: "Connect with AnyDesk", fr: "Connexion AnyDesk", it: "Connetti con AnyDesk") }
    static var heading: String { value(tr: "AnyDesk'e Bağlan", en: "Connect with AnyDesk", fr: "Se connecter avec AnyDesk", it: "Connetti con AnyDesk") }
    static var placeholder: String { value(tr: "AnyDesk ID veya alias", en: "AnyDesk ID or alias", fr: "ID AnyDesk ou alias", it: "ID AnyDesk o alias") }
    static var quit: String { value(tr: "Çıkış", en: "Quit", fr: "Quitter", it: "Esci") }
    static var connect: String { value(tr: "Bağlan", en: "Connect", fr: "Connexion", it: "Connetti") }
    static var emptyAddress: String { value(tr: "Bir AnyDesk ID veya alias girin.", en: "Enter an AnyDesk ID or alias.", fr: "Saisissez un ID AnyDesk ou un alias.", it: "Inserisci un ID AnyDesk o un alias.") }
    static var invalidAddress: String { value(tr: "Geçerli bir AnyDesk ID veya alias girin.", en: "Enter a valid AnyDesk ID or alias.", fr: "Saisissez un ID AnyDesk ou un alias valide.", it: "Inserisci un ID AnyDesk o un alias valido.") }
    static var anyDeskMissing: String { value(tr: "AnyDesk bulunamadı. Önce AnyDesk'i yükleyin.", en: "AnyDesk was not found. Install AnyDesk first.", fr: "AnyDesk est introuvable. Installez d'abord AnyDesk.", it: "AnyDesk non è stato trovato. Installa prima AnyDesk.") }

    private static func value(tr: String, en: String, fr: String, it: String) -> String {
        switch language {
        case "tr": tr
        case "fr": fr
        case "it": it
        default: en
        }
    }
}
