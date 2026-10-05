import SwiftUI
import Photos
import Combine

@MainActor
final class CategoryDetailViewModel: ObservableObject {
    let category: CategoryType
    
    @Published var items: [MediaItem] = []
    @Published var groups: [MediaGroup] = []
    @Published var isScanning: Bool = false
    @Published var isAuthorized: Bool = true
    @Published var isDeleting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedPreviewItem: MediaItem? = nil
    
    private let photoManager = PhotoLibraryManager.shared
    
    init(category: CategoryType, items: [MediaItem] = [], groups: [MediaGroup] = [], isScanning: Bool = false, isAuthorized: Bool = true) {
        self.category = category
        self.items = items
        self.groups = groups
        self.isScanning = isScanning
        self.isAuthorized = isAuthorized
        
        // Auto-select smart defaults for duplicate groups (keep first/newest item unselected, mark others selected)
        if !groups.isEmpty {
            autoSelectDuplicates()
        }
    }
    
    var totalSelectedCount: Int {
        if !groups.isEmpty {
            return groups.reduce(0) { $0 + $1.selectedCount }
        } else {
            return items.filter(\.isSelected).count
        }
    }
    
    var totalSelectedBytes: Int64 {
        if !groups.isEmpty {
            return groups.reduce(0) { groupAcc, group in
                groupAcc + group.items.filter(\.isSelected).reduce(0) { $0 + $1.fileSize }
            }
        } else {
            return items.filter(\.isSelected).reduce(0) { $0 + $1.fileSize }
        }
    }
    
    func toggleSelection(for itemID: String) {
        if !groups.isEmpty {
            for gIndex in 0..<groups.count {
                if let itemIndex = groups[gIndex].items.firstIndex(where: { $0.id == itemID }) {
                    groups[gIndex].items[itemIndex].isSelected.toggle()
                }
            }
        } else {
            if let index = items.firstIndex(where: { $0.id == itemID }) {
                items[index].isSelected.toggle()
            }
        }
    }
    
    func selectAll() {
        if !groups.isEmpty {
            for gIndex in 0..<groups.count {
                for iIndex in 0..<groups[gIndex].items.count {
                    groups[gIndex].items[iIndex].isSelected = true
                }
            }
        } else {
            for index in 0..<items.count {
                items[index].isSelected = true
            }
        }
    }
    
    func deselectAll() {
        if !groups.isEmpty {
            for gIndex in 0..<groups.count {
                for iIndex in 0..<groups[gIndex].items.count {
                    groups[gIndex].items[iIndex].isSelected = false
                }
            }
        } else {
            for index in 0..<items.count {
                items[index].isSelected = false
            }
        }
    }
    
    func autoSelectDuplicates() {
        for gIndex in 0..<groups.count {
            // Sort group items newest first
            let sorted = groups[gIndex].items.sorted {
                ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
            }
            // Keep the first item unselected, mark remaining items selected
            for iIndex in 0..<groups[gIndex].items.count {
                let currentItem = groups[gIndex].items[iIndex]
                if currentItem.id == sorted.first?.id {
                    groups[gIndex].items[iIndex].isSelected = false
                } else {
                    groups[gIndex].items[iIndex].isSelected = true
                }
            }
        }
    }
    
    func deleteSelectedAssets() async -> Bool {
        var selectedAssets: [PHAsset] = []
        if !groups.isEmpty {
            for group in groups {
                let selectedInGroup = group.items.filter(\.isSelected).map(\.asset)
                selectedAssets.append(contentsOf: selectedInGroup)
            }
        } else {
            selectedAssets = items.filter(\.isSelected).map(\.asset)
        }
        
        guard !selectedAssets.isEmpty else { return false }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            let success = try await photoManager.deleteAssets(selectedAssets)
            if success {
                let deletedIDs = Set(selectedAssets.map(\.localIdentifier))
                if !groups.isEmpty {
                    for gIndex in (0..<groups.count).reversed() {
                        groups[gIndex].items.removeAll { deletedIDs.contains($0.id) }
                        if groups[gIndex].items.count <= 1 {
                            groups.remove(at: gIndex)
                        }
                    }
                } else {
                    items.removeAll { deletedIDs.contains($0.id) }
                }
                return true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        return false
    }
}
