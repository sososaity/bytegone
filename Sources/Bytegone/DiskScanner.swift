import Foundation

actor DiskScanner {
    func scan(category: CleanupCategory, downloadAgeDays: Int) async -> [ScanItem] {
        let fm = FileManager.default
        var items: [ScanItem] = []

        for root in category.roots where fm.fileExists(atPath: root.path) {
            switch category {
            case .oldDownloads:
                items.append(contentsOf: scanOldFiles(in: root, olderThanDays: downloadAgeDays, category: category))
            case .appContainerCaches:
                if let containers = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
                    for container in containers {
                        let cacheDir = container.appending(path: "Data/Library/Caches")
                        if fm.fileExists(atPath: cacheDir.path) {
                            items.append(contentsOf: scanChildren(of: cacheDir, category: category))
                        }
                    }
                }
            default:
                items.append(contentsOf: scanChildren(of: root, category: category))
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanChildren(of root: URL, category: CleanupCategory) -> [ScanItem] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
        ) else { return [] }

        // Broad maintenance categories (User Caches) shouldn't double-count
        // children that have a dedicated developer category.
        let exclusions: Set<String> = category.group == .maintenance
            ? CleanupCategory.specializedRootPaths
            : []

        var results: [ScanItem] = []
        for entry in entries where SafetyGuard.isSafe(entry) {
            if exclusions.contains(entry.standardizedFileURL.path) { continue }
            let size = sizeOnDisk(of: entry)
            if size > 0 {
                results.append(ScanItem(url: entry, size: size, category: category))
            }
        }
        return results
    }

    private func scanOldFiles(in root: URL, olderThanDays days: Int, category: CleanupCategory) -> [ScanItem] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return [] }

        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
        var results: [ScanItem] = []
        for entry in entries where SafetyGuard.isSafe(entry) {
            guard let values = try? entry.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modified = values.contentModificationDate,
                  modified < cutoff else { continue }
            let size = sizeOnDisk(of: entry)
            if size > 0 {
                results.append(ScanItem(url: entry, size: size, category: category))
            }
        }
        return results
    }

    private func sizeOnDisk(of url: URL) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(values?.fileSize ?? 0)
        }

        var total: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]
        if let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { _, _ in true }
        ) {
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                      values.isRegularFile == true else { continue }
                total += Int64(values.fileSize ?? 0)
            }
        }
        return total
    }
}
