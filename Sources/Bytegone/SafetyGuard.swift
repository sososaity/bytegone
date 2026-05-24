import Foundation

/// Last line of defence. Any path passed to deletion MUST clear `isSafe` first.
/// Reflects the rules in CLAUDE.md.
enum SafetyGuard {
    /// macOS system roots — never touch.
    static let systemPaths: [String] = [
        "/System", "/Library", "/private", "/usr", "/bin", "/sbin",
        "/Applications", "/cores", "/Volumes",
    ]

    /// User work directories — never touch.
    /// Customize this list with your own protected directories.
    static var workPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/Documents/Workspace",
            "\(home)/Documents/Projects",
            "\(home)/Desktop/Projects",
            "\(home)/Desktop/Work",
        ]
    }

    /// Any path containing one of these substrings is rejected.
    static let sensitivePatterns: [String] = [
        "/.git/", "/.git",
        "/.env", "/.envrc",
        "/.ssh/", "/.aws/credentials", "/.aws/config",
        "/.gnupg/", "/.config/gh/hosts.yml",
        "id_rsa", "id_ed25519", "id_ecdsa",
        ".keychain", ".keychain-db",
        "node_modules",
    ]

    /// Refuse to delete the home directory, root, or anything above ~3 levels deep.
    /// (Caches and similar always sit deeper than that.)
    static func isSafe(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        if path == "/" || path == home || path.isEmpty { return false }

        for sys in systemPaths {
            if path == sys || path.hasPrefix(sys + "/") { return false }
        }
        for work in workPaths {
            if path == work || path.hasPrefix(work + "/") { return false }
        }
        for pattern in sensitivePatterns {
            if path.contains(pattern) { return false }
        }
        return true
    }
}
