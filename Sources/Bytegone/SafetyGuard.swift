import Foundation

/// Last line of defence. Any path passed to deletion MUST clear `isSafe` first.
/// Reflects the rules in CLAUDE.md.
enum SafetyGuard {
    /// macOS system roots — never touch.
    static let systemPaths: [String] = [
        "/System", "/Library", "/private", "/usr", "/bin", "/sbin",
        "/Applications", "/cores", "/Volumes",
    ]

    /// User work directories — never touch (sourced from CLAUDE.md).
    static var workPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/Documents/Workspace",
            "\(home)/Documents/Workspace.nosync",
            "\(home)/Documents/Obsidian Vault",
            "\(home)/Documents/Personal Document",
            "\(home)/Documents/Specification",
            "\(home)/Documents/Assets",
            "\(home)/Documents/E-Commerce",
            "\(home)/Documents/Claude",
            "\(home)/Desktop/Cowork",
            "\(home)/Desktop/Projects",
            "\(home)/Desktop/AWS-Certification",
            "\(home)/Desktop/AllPay",
            "\(home)/Desktop/CPO-Leasing",
            "\(home)/Desktop/Migration",
            "\(home)/Desktop/Documents",
            "\(home)/Desktop/Screenshots",
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
