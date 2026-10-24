import AppKit
import SwiftUI

private enum Page { case connect, settings }

struct RootView: View {
    @ObservedObject var shortcutModel: ShortcutSettingsModel
    @ObservedObject var connectionModel: ConnectionModel
    @State private var page: Page = .connect

    var body: some View {
        Group {
            switch page {
            case .connect: ConnectionView(model: connectionModel) { page = .settings }
            case .settings: SettingsView(model: shortcutModel) { page = .connect }
            }
        }
        .frame(width: 320)
        .onChange(of: connectionModel.focusRequest) { _ in page = .connect }
    }
}

private struct ConnectionView: View {
    @ObservedObject var model: ConnectionModel
    let openSettings: () -> Void
    @State private var message: String?
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "display").foregroundStyle(.secondary)
                Text(Copy.heading).font(.headline)
                Spacer()
                Button(action: openSettings) { Image(systemName: "gearshape") }
                    .buttonStyle(.plain)
                    .help(Copy.settings)
            }

            TextField(Copy.placeholder, text: $model.address)
                .textFieldStyle(.roundedBorder)
                .focused($isAddressFocused)
                .onSubmit(connect)

            if let message {
                Text(message).font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button(Copy.quit) { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
                Spacer()
                Button(Copy.connect, action: connect)
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .disabled(model.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .onAppear {
            message = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isAddressFocused = true }
        }
        .onChange(of: model.focusRequest) { _ in
            message = nil
            isAddressFocused = true
        }
    }

    private func connect() {
        message = nil
        var cleaned = model.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
            cleaned.removeAll(where: \Character.isWhitespace)
        }
        guard !cleaned.isEmpty else { message = Copy.emptyAddress; return }

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

private struct SettingsView: View {
    @ObservedObject var model: ShortcutSettingsModel
    let goBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Button(action: goBack) { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain).help(Copy.back)
                Text(Copy.settings).font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(Copy.globalShortcut).font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: model.shortcut) { model.update($0) }
                    .frame(height: 30)
                Text(Copy.shortcutHint).font(.caption).foregroundStyle(.secondary)
                if let error = model.error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Toggle(Copy.clipboardDetection, isOn: Binding(
                    get: { model.autoOpenFromClipboard },
                    set: { model.setAutoOpenFromClipboard($0) }
                ))
                Text(Copy.clipboardHint).font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Button(Copy.resetShortcut) { model.reset() }
                Spacer()
                Button(Copy.done, action: goBack).buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
    }
}
