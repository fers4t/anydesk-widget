import AppKit
import Combine
import CryptoKit
import Foundation

struct SemanticVersion: Comparable, Equatable, Sendable {
    let components: [Int]

    init?(_ value: String) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let versionPart = normalized.split(separator: "-", maxSplits: 1).first ?? ""
        let numbers = versionPart.split(separator: ".", omittingEmptySubsequences: false)
        guard !numbers.isEmpty, numbers.allSatisfy({ Int($0) != nil }) else { return nil }
        components = numbers.map { Int($0)! }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

struct PreparedUpdate: Sendable {
    let version: String
    let appURL: URL
}

private struct GitHubRelease: Decodable, Sendable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

private struct GitHubAsset: Decodable, Sendable {
    let name: String
    let browserDownloadURL: URL
    let digest: String?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case digest
    }
}

enum UpdateState {
    case idle
    case checking
    case downloading(version: String)
    case ready(PreparedUpdate)
    case installing
    case failed(String)
}

@MainActor
final class UpdateModel: ObservableObject {
    @Published private(set) var state: UpdateState = .idle
    @Published private(set) var manualStatus: String?
    var onUpdateReady: (() -> Void)?
    var onStateChange: ((UpdateState) -> Void)?

    private var timer: Timer?
    private var updateTask: Task<Void, Never>?

    var preparedUpdate: PreparedUpdate? {
        guard case let .ready(update) = state else { return nil }
        return update
    }

    func start() {
        checkForUpdates()
        timer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkForUpdates() }
        }
    }

    var isBusy: Bool {
        switch state {
        case .checking, .downloading, .installing: true
        default: false
        }
    }

    func checkForUpdates(manual: Bool = false) {
        guard updateTask == nil, preparedUpdate == nil else { return }
        if manual { manualStatus = nil }
        setState(.checking)
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

        updateTask = Task { [weak self] in
            do {
                guard let release = try await GitHubUpdateService.latestUpdate(after: currentVersion) else {
                    self?.setState(.idle)
                    if manual { self?.manualStatus = Copy.updateUpToDate }
                    self?.updateTask = nil
                    return
                }
                self?.setState(.downloading(version: release.version))
                if manual { self?.manualStatus = String(format: Copy.updateDownloading, release.version) }
                let prepared = try await GitHubUpdateService.downloadAndPrepare(release)
                self?.setState(.ready(prepared))
                if manual { self?.manualStatus = String(format: Copy.updateReadyVersion, prepared.version) }
                self?.updateTask = nil
                self?.onUpdateReady?()
            } catch is CancellationError {
                self?.setState(.idle)
                self?.updateTask = nil
            } catch {
                if manual {
                    self?.manualStatus = String(format: Copy.updateFailed, error.localizedDescription)
                }
                self?.setState(.idle)
                self?.updateTask = nil
            }
        }
    }

    func installAndRestart() {
        guard let update = preparedUpdate else { return }
        setState(.installing)
        do {
            try GitHubUpdateService.installAndRestart(update)
        } catch {
            setState(.failed(error.localizedDescription))
        }
    }

    private func setState(_ newState: UpdateState) {
        state = newState
        onStateChange?(newState)
    }
}

private struct AvailableUpdate: Sendable {
    let version: String
    let asset: GitHubAsset
}

private enum UpdateError: LocalizedError {
    case invalidResponse
    case missingAsset
    case missingDigest
    case invalidDigest
    case invalidArchive
    case invalidApplication
    case invalidSignature
    case cannotReplaceApplication

    var errorDescription: String? {
        switch self {
        case .invalidResponse: Copy.updateInvalidResponse
        case .missingAsset: Copy.updateMissingAsset
        case .missingDigest: Copy.updateMissingDigest
        case .invalidDigest: Copy.updateInvalidDigest
        case .invalidArchive: Copy.updateInvalidArchive
        case .invalidApplication: Copy.updateInvalidApplication
        case .invalidSignature: Copy.updateInvalidSignature
        case .cannotReplaceApplication: Copy.updateCannotInstall
        }
    }
}

private enum GitHubUpdateService {
    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/fers4t/anydesk-widget/releases/latest")!
    private static let expectedBundleIdentifier = "com.fersat.anydesk-widget"

    static func latestUpdate(after currentVersion: String) async throws -> AvailableUpdate? {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("AnyDeskWidget/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard let latest = SemanticVersion(release.tagName),
              let current = SemanticVersion(currentVersion), latest > current else { return nil }
        guard let asset = release.assets.first(where: {
            $0.name.hasPrefix("AnyDesk-Baglan-") && $0.name.hasSuffix(".zip")
        }) else { throw UpdateError.missingAsset }
        return AvailableUpdate(version: release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV")), asset: asset)
    }

    static func downloadAndPrepare(_ update: AvailableUpdate) async throws -> PreparedUpdate {
        guard let digest = update.asset.digest,
              digest.lowercased().hasPrefix("sha256:") else { throw UpdateError.missingDigest }

        var request = URLRequest(url: update.asset.browserDownloadURL)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("AnyDeskWidget/Updater", forHTTPHeaderField: "User-Agent")
        let (temporaryURL, response) = try await URLSession.shared.download(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }

        return try await Task.detached(priority: .utility) {
            try prepareArchive(at: temporaryURL, expectedDigest: digest, version: update.version)
        }.value
    }

    nonisolated private static func prepareArchive(at downloadedURL: URL, expectedDigest: String, version: String) throws -> PreparedUpdate {
        let data = try Data(contentsOf: downloadedURL)
        let actualDigest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let expected = String(expectedDigest.dropFirst("sha256:".count)).lowercased()
        guard actualDigest == expected else { throw UpdateError.invalidDigest }

        let fileManager = FileManager.default
        let cacheRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(expectedBundleIdentifier, isDirectory: true)
            .appendingPathComponent("Updates", isDirectory: true)
        let stagingRoot = cacheRoot.appendingPathComponent(version, isDirectory: true)
        let archiveURL = stagingRoot.appendingPathComponent("update.zip")
        let extractedURL = stagingRoot.appendingPathComponent("extracted", isDirectory: true)

        if fileManager.fileExists(atPath: stagingRoot.path) {
            try fileManager.removeItem(at: stagingRoot)
        }
        try fileManager.createDirectory(at: extractedURL, withIntermediateDirectories: true)
        try fileManager.copyItem(at: downloadedURL, to: archiveURL)
        try run("/usr/bin/ditto", arguments: ["-x", "-k", archiveURL.path, extractedURL.path], failure: .invalidArchive)

        guard let enumerator = fileManager.enumerator(at: extractedURL, includingPropertiesForKeys: nil),
              let appURL = enumerator.compactMap({ $0 as? URL }).first(where: { $0.pathExtension == "app" }),
              let bundle = Bundle(url: appURL),
              bundle.bundleIdentifier == expectedBundleIdentifier,
              let stagedVersionString = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let stagedVersion = SemanticVersion(stagedVersionString),
              let expectedVersion = SemanticVersion(version), stagedVersion == expectedVersion else {
            throw UpdateError.invalidApplication
        }

        try run("/usr/bin/codesign", arguments: ["--verify", "--deep", "--strict", appURL.path], failure: .invalidSignature)
        return PreparedUpdate(version: version, appURL: appURL)
    }

    @MainActor
    static func installAndRestart(_ update: PreparedUpdate) throws {
        let fileManager = FileManager.default
        let currentURL = Bundle.main.bundleURL
        guard currentURL.pathExtension == "app",
              Bundle.main.bundleIdentifier == expectedBundleIdentifier else {
            throw UpdateError.cannotReplaceApplication
        }

        let parentURL = currentURL.deletingLastPathComponent()
        if fileManager.isWritableFile(atPath: parentURL.path) {
            do {
                try replaceDirectly(source: update.appURL, destination: currentURL)
            } catch {
                try installWithAdministratorPrivileges(source: update.appURL, destination: currentURL)
            }
        } else if fileManager.isWritableFile(atPath: currentURL.path) {
            // Finder commonly gives the user ownership of the app bundle, while
            // /Applications itself remains protected. Updating in place needs no prompt.
            // A directory can report itself writable even when files inside the
            // bundle are owned by another user (for example after an admin install).
            // If the in-place copy fails, retry through the authenticated path.
            do {
                try run("/usr/bin/ditto", arguments: [update.appURL.path, currentURL.path], failure: .cannotReplaceApplication)
            } catch {
                try installWithAdministratorPrivileges(source: update.appURL, destination: currentURL)
            }
        } else {
            try installWithAdministratorPrivileges(source: update.appURL, destination: currentURL)
        }

        try run("/usr/bin/codesign", arguments: ["--verify", "--deep", "--strict", currentURL.path], failure: .invalidSignature)

        let helperURL = fileManager.temporaryDirectory
            .appendingPathComponent("anydesk-widget-relaunch-\(UUID().uuidString).sh")
        let script = "#!/bin/sh\nsleep 1\n/usr/bin/open \"$1\"\n/bin/rm -f \"$0\"\n"
        try script.write(to: helperURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: helperURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [helperURL.path, currentURL.path]
        try process.run()
        NSApplication.shared.terminate(nil)
    }

    nonisolated private static func replaceDirectly(source: URL, destination: URL) throws {
        let fileManager = FileManager.default
        let incomingURL = destination.deletingLastPathComponent()
            .appendingPathComponent(".AnyDeskWidget-update-\(UUID().uuidString).app")
        do {
            try fileManager.copyItem(at: source, to: incomingURL)
            _ = try fileManager.replaceItemAt(destination, withItemAt: incomingURL)
        } catch {
            try? fileManager.removeItem(at: incomingURL)
            throw error
        }
    }

    nonisolated private static func installWithAdministratorPrivileges(source: URL, destination: URL) throws {
        let parent = destination.deletingLastPathComponent()
        let token = UUID().uuidString
        let incoming = parent.appendingPathComponent(".AnyDeskWidget-update-\(token).app")
        let backup = parent.appendingPathComponent(".AnyDeskWidget-backup-\(token).app")

        let command = [
            "set -e",
            "/usr/bin/ditto \(shellQuote(source.path)) \(shellQuote(incoming.path))",
            "/bin/mv \(shellQuote(destination.path)) \(shellQuote(backup.path))",
            "if /bin/mv \(shellQuote(incoming.path)) \(shellQuote(destination.path)); then /bin/rm -rf \(shellQuote(backup.path)); else /bin/mv \(shellQuote(backup.path)) \(shellQuote(destination.path)); exit 1; fi"
        ].joined(separator: "; ")
        let appleScript = "do shell script \(appleScriptLiteral(command)) with administrator privileges"
        try run("/usr/bin/osascript", arguments: ["-e", appleScript], failure: .cannotReplaceApplication)
    }

    nonisolated private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }

    nonisolated private static func appleScriptLiteral(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    nonisolated private static func run(_ executable: String, arguments: [String], failure: UpdateError) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw failure }
    }
}
