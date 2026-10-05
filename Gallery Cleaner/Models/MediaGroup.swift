import Foundation

struct MediaGroup: Identifiable, Hashable {
    let id: String
    var items: [MediaItem]
    
    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.fileSize }
    }
    
    // Wasted storage calculation: sum of size of all items except the one kept (usually 1 kept item)
    var reclaimableSize: Int64 {
        guard items.count > 1 else { return 0 }
        let selectedSize = items.filter(\.isSelected).reduce(0) { $0 + $1.fileSize }
        if selectedSize > 0 {
            return selectedSize
        }
        // Default estimate: total size minus the largest/first item
        let sorted = items.sorted { $0.fileSize > $1.fileSize }
        return sorted.dropFirst().reduce(0) { $0 + $1.fileSize }
    }
    
    var selectedCount: Int {
        items.filter(\.isSelected).count
    }
}
