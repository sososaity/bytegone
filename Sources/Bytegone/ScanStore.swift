import Foundation
import SwiftUI

@MainActor
final class ScanStore: ObservableObject {
    @Published var itemsByCategory: [CleanupCategory: [ScanItem]] = [:]
    @Published var isScanning: Bool = false
    @Published var scanningCategory: CleanupCategory?
    @Published var lastResult: CleanupResult?
    @Published var downloadAgeDays: Int = 30
    @Published var selection: SidebarSelection = .overview
    @Published var showCompletion: Bool = false
    @Published var fullDiskAccess: PermissionStatus = .unknown

    private let scanner = DiskScanner()

    init() {
        refreshPermissions()
    }

    func refreshPermissions() {
        let status = PermissionsService.checkFullDiskAccess()
        if fullDiskAccess != status {
            withAnimation(.smooth(duration: 0.35)) { fullDiskAccess = status }
        } else {
            fullDiskAccess = status
        }
    }

    var allItems: [ScanItem] {
        itemsByCategory.values.flatMap { $0 }
    }

    var selectedItems: [ScanItem] {
        allItems.filter(\.selected)
    }

    var totalSelected: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    var totalScanned: Int64 {
        allItems.reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int { selectedItems.count }
    var totalCount: Int { allItems.count }

    var hasScanned: Bool { !itemsByCategory.isEmpty }

    func size(of category: CleanupCategory) -> Int64 {
        (itemsByCategory[category] ?? []).reduce(0) { $0 + $1.size }
    }

    func selectedSize(of category: CleanupCategory) -> Int64 {
        (itemsByCategory[category] ?? []).filter(\.selected).reduce(0) { $0 + $1.size }
    }

    func scanAll() async {
        isScanning = true
        defer {
            isScanning = false
            scanningCategory = nil
        }

        let days = downloadAgeDays
        var fresh: [CleanupCategory: [ScanItem]] = [:]
        for category in CleanupCategory.allCases {
            scanningCategory = category
            fresh[category] = await scanner.scan(category: category, downloadAgeDays: days)
            // Push partial result so the sidebar fills in progressively.
            withAnimation(.smooth(duration: 0.4)) {
                itemsByCategory = fresh
            }
        }
        lastResult = nil
    }

    func cleanSelected() {
        let toClean = selectedItems
        let result = CleanupService.clean(toClean)
        lastResult = result

        withAnimation(.smooth(duration: 0.45)) {
            for category in itemsByCategory.keys {
                itemsByCategory[category]?.removeAll { $0.selected }
            }
        }
        showCompletion = true
    }

    func toggle(_ item: ScanItem) {
        guard let idx = itemsByCategory[item.category]?.firstIndex(where: { $0.id == item.id }) else { return }
        itemsByCategory[item.category]?[idx].selected.toggle()
    }

    func selectAll(in category: CleanupCategory, _ selected: Bool) {
        guard var items = itemsByCategory[category] else { return }
        for i in items.indices { items[i].selected = selected }
        itemsByCategory[category] = items
    }

    func selectAllEverywhere(_ selected: Bool) {
        for category in itemsByCategory.keys {
            selectAll(in: category, selected)
        }
    }
}
