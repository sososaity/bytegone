import Foundation

enum CleanupService {
    static func clean(_ items: [ScanItem]) -> CleanupResult {
        var result = CleanupResult()
        let fm = FileManager.default

        for item in items {
            guard SafetyGuard.isSafe(item.url) else {
                result.errors.append("BLOCKED by SafetyGuard: \(item.url.path)")
                continue
            }

            do {
                var resultURL: NSURL?
                try fm.trashItem(at: item.url, resultingItemURL: &resultURL)
                result.deletedCount += 1
                result.freedBytes += item.size
            } catch {
                result.errors.append("\(item.url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        return result
    }
}
