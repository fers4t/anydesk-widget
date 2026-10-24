import AppKit
import Combine

enum AnyDeskAddressDetector {
    private static let pattern = #"^\s*(?:[0-9]{9,10}|[0-9]{3}\s+[0-9]{3}\s+[0-9]{3}|[0-9]\s+[0-9]{3}\s+[0-9]{3}\s+[0-9]{3})\s*$"#

    static func numericID(from value: String) -> String? {
        guard value.range(of: pattern, options: .regularExpression) != nil else { return nil }
        let normalized = value.filter(\.isNumber)
        guard (9...10).contains(normalized.count) else { return nil }
        return normalized
    }
}

@MainActor
final class ConnectionModel: ObservableObject {
    @Published var address = ""
    @Published private(set) var focusRequest = 0
    @Published private(set) var notice: String?

    func prepare(address: String) {
        self.address = address
        notice = nil
        focusRequest += 1
    }

    func showNotice(_ message: String) {
        notice = message
        focusRequest += 1
    }
}

@MainActor
final class ClipboardMonitor: NSObject {
    var onAddressDetected: ((String) -> Void)?
    var isEnabled: (() -> Bool)?

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.45, target: self, selector: #selector(inspectClipboard), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func inspectClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard isEnabled?() ?? true else { return }

        if let value = pasteboard.string(forType: .string),
           let address = AnyDeskAddressDetector.numericID(from: value) {
            onAddressDetected?(address)
            return
        }

        if let image = NSImage(pasteboard: pasteboard) {
            Task { [weak self] in
                guard let address = try? await ImageIDRecognizer.numericID(in: image) else { return }
                self?.onAddressDetected?(address)
            }
        }
    }
}
