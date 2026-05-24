import Foundation
import AppKit

enum PermissionStatus: Equatable {
    case granted
    case denied
    case unknown

    var label: String {
        switch self {
        case .granted: return "Granted"
        case .denied:  return "Not granted"
        case .unknown: return "Unknown"
        }
    }
}

enum PermissionsService {
    /// Heuristic: try to read `/Library/Application Support/com.apple.TCC/TCC.db`.
    /// Reading it requires Full Disk Access. A successful read means we have it.
    static func checkFullDiskAccess() -> PermissionStatus {
        let path = "/Library/Application Support/com.apple.TCC/TCC.db"
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return .unknown }
        do {
            let handle = try FileHandle(forReadingFrom: url)
            try handle.close()
            return .granted
        } catch {
            return .denied
        }
    }

    /// Best-effort check: enumerate ~/Library/Containers — if denied, FDA is likely missing.
    static func canReadAppContainers() -> Bool {
        let url = FileManager.default
            .homeDirectoryForCurrentUser
            .appending(path: "Library/Containers")
        return (try? FileManager.default.contentsOfDirectory(atPath: url.path)) != nil
    }

    static func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    static func openPrivacySettingsRoot() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }
}
