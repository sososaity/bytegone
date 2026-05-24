import Foundation
import AppKit

/// Single source of truth for the support / donation destination.
/// Update the URL here if the platform changes.
enum SupportLink {
    static let url = URL(string: "https://buymeacoffee.com/pakortra")!
    static let cta = "Buy me a coffee"
    static let platform = "Buy Me a Coffee"

    /// Threshold above which the post-cleanup prompt appears.
    static let promptThresholdBytes: Int64 = 5 * 1024 * 1024 * 1024  // 5 GB

    static func open() {
        NSWorkspace.shared.open(url)
    }
}
