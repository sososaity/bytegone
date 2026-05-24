import Foundation
import SwiftUI

enum CategoryGroup: String, CaseIterable {
    case maintenance = "MAINTENANCE"
    case developer   = "DEVELOPER"
}

enum CleanupCategory: String, CaseIterable, Identifiable {
    // Maintenance
    case userCaches         = "User Caches"
    case derivedData        = "Xcode DerivedData"
    case simulatorCaches    = "iOS Simulator Caches"
    case appContainerCaches = "App Container Caches"
    case logs               = "User Logs"
    case trash              = "Trash"
    case oldDownloads       = "Old Downloads"

    // Developer
    case cocoapodsCache     = "CocoaPods Cache"
    case pipCache           = "pip Cache"
    case huggingfaceCache   = "Hugging Face Cache"
    case ollamaModels       = "Ollama Models"
    case vsCodeStorage      = "VS Code Storage"
    case jetbrainsCaches    = "JetBrains Caches"

    var id: String { rawValue }

    var group: CategoryGroup {
        switch self {
        case .userCaches, .derivedData, .simulatorCaches, .appContainerCaches,
             .logs, .trash, .oldDownloads:
            return .maintenance
        case .cocoapodsCache, .pipCache, .huggingfaceCache,
             .ollamaModels, .vsCodeStorage, .jetbrainsCaches:
            return .developer
        }
    }

    var icon: String {
        switch self {
        case .userCaches:         return "internaldrive"
        case .derivedData:        return "hammer.fill"
        case .simulatorCaches:    return "iphone"
        case .appContainerCaches: return "shippingbox.fill"
        case .logs:               return "doc.text.fill"
        case .trash:              return "trash.fill"
        case .oldDownloads:       return "arrow.down.circle.fill"
        case .cocoapodsCache:     return "cube.box.fill"
        case .pipCache:           return "snake.circle.fill"
        case .huggingfaceCache:   return "brain.head.profile.fill"
        case .ollamaModels:       return "cpu.fill"
        case .vsCodeStorage:      return "chevron.left.forwardslash.chevron.right"
        case .jetbrainsCaches:    return "j.square.fill"
        }
    }

    var hint: String {
        switch self {
        case .userCaches:         return "App caches and package-manager caches"
        case .derivedData:        return "Xcode build artifacts — will rebuild on next build"
        case .simulatorCaches:    return "Cached simulator data, not the simulators themselves"
        case .appContainerCaches: return "Sandboxed app caches under ~/Library/Containers"
        case .logs:               return "Application and system user logs"
        case .trash:              return "Already-deleted items still occupying disk"
        case .oldDownloads:       return "Files in ~/Downloads older than 30 days"
        case .cocoapodsCache:     return "Cached pod specs and downloads — re-fetched on next pod install"
        case .pipCache:           return "Python wheel cache — re-downloaded as needed"
        case .huggingfaceCache:   return "Downloaded model weights and datasets — can be huge"
        case .ollamaModels:       return "Local LLM weights — single models can be 4–8 GB+"
        case .vsCodeStorage:      return "VS Code extension storage and caches"
        case .jetbrainsCaches:    return "JetBrains IDE caches and logs (IntelliJ, WebStorm, etc.)"
        }
    }

    var accent: Color {
        switch self {
        case .userCaches:         return Color(red: 0.36, green: 0.62, blue: 1.00) // blue
        case .derivedData:        return Color(red: 1.00, green: 0.58, blue: 0.20) // orange
        case .simulatorCaches:    return Color(red: 1.00, green: 0.42, blue: 0.65) // pink
        case .appContainerCaches: return Color(red: 0.66, green: 0.45, blue: 1.00) // purple
        case .logs:               return Color(red: 0.30, green: 0.79, blue: 0.78) // teal
        case .trash:              return Color(red: 0.95, green: 0.34, blue: 0.34) // red
        case .oldDownloads:       return Color(red: 0.36, green: 0.85, blue: 0.55) // green
        case .cocoapodsCache:     return Color(red: 0.95, green: 0.38, blue: 0.30) // coral
        case .pipCache:           return Color(red: 0.30, green: 0.65, blue: 0.95) // sky
        case .huggingfaceCache:   return Color(red: 1.00, green: 0.78, blue: 0.20) // amber
        case .ollamaModels:       return Color(red: 0.55, green: 0.85, blue: 0.45) // lime
        case .vsCodeStorage:      return Color(red: 0.20, green: 0.62, blue: 0.94) // vscode blue
        case .jetbrainsCaches:    return Color(red: 0.93, green: 0.30, blue: 0.55) // jetbrains pink
        }
    }

    var roots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .userCaches:
            return [
                home.appending(path: "Library/Caches"),
                home.appending(path: ".cache"),
                home.appending(path: ".npm/_cacache"),
                home.appending(path: ".yarn/cache"),
                home.appending(path: ".pnpm-store"),
                home.appending(path: ".bun/install/cache"),
                home.appending(path: ".gradle/caches"),
            ]
        case .derivedData:
            return [home.appending(path: "Library/Developer/Xcode/DerivedData")]
        case .simulatorCaches:
            return [home.appending(path: "Library/Developer/CoreSimulator/Caches")]
        case .appContainerCaches:
            return [home.appending(path: "Library/Containers")]
        case .logs:
            return [home.appending(path: "Library/Logs")]
        case .trash:
            return [home.appending(path: ".Trash")]
        case .oldDownloads:
            return [home.appending(path: "Downloads")]
        case .cocoapodsCache:
            return [home.appending(path: "Library/Caches/CocoaPods")]
        case .pipCache:
            return [
                home.appending(path: "Library/Caches/pip"),
                home.appending(path: ".cache/pip"),
            ]
        case .huggingfaceCache:
            return [
                home.appending(path: ".cache/huggingface"),
                home.appending(path: "Library/Caches/huggingface"),
            ]
        case .ollamaModels:
            return [home.appending(path: ".ollama/models")]
        case .vsCodeStorage:
            return [
                home.appending(path: "Library/Application Support/Code/User/globalStorage"),
                home.appending(path: "Library/Application Support/Code/Cache"),
                home.appending(path: "Library/Application Support/Code/CachedData"),
                home.appending(path: "Library/Application Support/Code/CachedExtensionVSIXs"),
                home.appending(path: "Library/Application Support/Code/logs"),
            ]
        case .jetbrainsCaches:
            return [
                home.appending(path: "Library/Caches/JetBrains"),
                home.appending(path: "Library/Logs/JetBrains"),
            ]
        }
    }

    /// Roots of every "specialized" (developer) category — used by broader categories
    /// to skip these subdirs and avoid double-counting them.
    static var specializedRootPaths: Set<String> {
        var paths: Set<String> = []
        for cat in CleanupCategory.allCases where cat.group == .developer {
            for root in cat.roots {
                paths.insert(root.standardizedFileURL.path)
            }
        }
        return paths
    }
}

struct ScanItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let category: CleanupCategory
    var selected: Bool = true
}

struct CleanupResult {
    var deletedCount: Int = 0
    var freedBytes: Int64 = 0
    var errors: [String] = []
}

enum SidebarSelection: Hashable {
    case overview
    case category(CleanupCategory)
    case devTools
    case schedule
    case permissions
}

func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}
