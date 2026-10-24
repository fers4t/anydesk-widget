import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginModel: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var message: String?

    private let preferenceKey = "launchAtLogin"

    init() {
        if UserDefaults.standard.object(forKey: preferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: preferenceKey)
        }
        isEnabled = UserDefaults.standard.bool(forKey: preferenceKey)
    }

    func start() {
        guard isEnabled else { return }
        apply(enabled: true, persist: false)
    }

    func setEnabled(_ enabled: Bool) {
        apply(enabled: enabled, persist: true)
    }

    private func apply(enabled: Bool, persist: Bool) {
        message = nil
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
                isEnabled = true
                if SMAppService.mainApp.status == .requiresApproval {
                    message = Copy.launchAtLoginNeedsApproval
                }
            } else {
                if SMAppService.mainApp.status != .notRegistered {
                    try SMAppService.mainApp.unregister()
                }
                isEnabled = false
            }
            if persist { UserDefaults.standard.set(enabled, forKey: preferenceKey) }
        } catch {
            isEnabled = SMAppService.mainApp.status == .enabled
            message = String(format: Copy.launchAtLoginFailed, error.localizedDescription)
        }
    }
}
