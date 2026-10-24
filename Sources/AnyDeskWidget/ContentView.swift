import AppKit
import SwiftUI

private enum Page { case connect, settings }

struct RootView: View {
    @ObservedObject var shortcutModel: ShortcutSettingsModel
    @ObservedObject var connectionModel: ConnectionModel
    @ObservedObject var updateModel: UpdateModel
    @ObservedObject var launchAtLoginModel: LaunchAtLoginModel
    @State private var page: Page = .connect

    var body: some View {
        Group {
            switch page {
            case .connect: ConnectionView(model: connectionModel, updateModel: updateModel) { page = .settings }
            case .settings:
                SettingsView(
                    model: shortcutModel,
                    updateModel: updateModel,
                    launchAtLoginModel: launchAtLoginModel
                ) { page = .connect }
            }
        }
        .frame(width: 320)
        .onChange(of: connectionModel.focusRequest) { _ in page = .connect }
        .onChange(of: updateModel.preparedUpdate?.version) { _ in
            if updateModel.preparedUpdate != nil { page = .connect }
        }
    }
}

private struct ConnectionView: View {
    @ObservedObject var model: ConnectionModel
    @ObservedObject var updateModel: UpdateModel
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

            if let update = updateModel.preparedUpdate {
                VStack(alignment: .leading, spacing: 7) {
                    Label(String(format: Copy.updateReadyVersion, update.version), systemImage: "arrow.down.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text(Copy.updateReadyDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(Copy.updateAndRestart) { updateModel.installAndRestart() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            } else if case .installing = updateModel.state {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(Copy.updateInstalling).font(.caption)
                }
            } else if case let .failed(error) = updateModel.state {
                Text(String(format: Copy.updateFailed, error))
                    .font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
    @ObservedObject var updateModel: UpdateModel
    @ObservedObject var launchAtLoginModel: LaunchAtLoginModel
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

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Toggle(Copy.launchAtLogin, isOn: Binding(
                    get: { launchAtLoginModel.isEnabled },
                    set: { launchAtLoginModel.setEnabled($0) }
                ))
                if let message = launchAtLoginModel.message {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.updates).font(.subheadline.weight(.medium))
                    if let status = updateModel.manualStatus {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Button(Copy.checkForUpdates) { updateModel.checkForUpdates(manual: true) }
                    .disabled(updateModel.isBusy || updateModel.preparedUpdate != nil)
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
