import Foundation
import Photos

actor DuplicateDetector {
    
    /// Finds exact duplicate photos grouped by file size, dimensions, and creation date timestamp proximity
    func findDuplicatePhotos(from assets: [PHAsset], progressHandler: @Sendable (Double) -> Void) async -> [MediaGroup] {
        guard !assets.isEmpty else { return [] }
        
        var mediaItems: [MediaItem] = []
        let totalCount = Double(assets.count)
        
        for (index, asset) in assets.enumerated() {
            let size = PhotoLibraryManager.getFileSize(for: asset)
            let item = MediaItem(asset: asset, fileSize: size)
            mediaItems.append(item)
            
            if index % 50 == 0 || index == assets.count - 1 {
                let progress = Double(index + 1) / totalCount * 0.5
                progressHandler(progress)
            }
        }
        
        // Group by combined key: (fileSize, pixelWidth, pixelHeight)
        var sizeMap: [String: [MediaItem]] = [:]
        for item in mediaItems {
            // If file size is 0, fall back to width/height/duration
            let key = "\(item.fileSize)_\(item.pixelWidth)_\(item.pixelHeight)"
            sizeMap[key, default: []].append(item)
        }
        
        var duplicateGroups: [MediaGroup] = []
        var groupIndex = 1
        
        let candidateKeys = sizeMap.keys.filter { (sizeMap[$0]?.count ?? 0) > 1 }
        let totalCandidates = Double(candidateKeys.count)
        var processedCandidates = 0.0
        
        for key in candidateKeys {
            guard let items = sizeMap[key] else { continue }
            
            // Sub-group by exact creation timestamp or burst identifiers
            var exactMap: [String: [MediaItem]] = [:]
            for item in items {
                let timeKey: String
                if let date = item.creationDate {
                    // Truncate timestamp to exact second
                    timeKey = "\(Int(date.timeIntervalSince1970))"
                } else {
                    timeKey = "unknown"
                }
                exactMap[timeKey, default: []].append(item)
            }
            
            for (_, subItems) in exactMap where subItems.count > 1 {
                let group = MediaGroup(id: "dup_photo_\(groupIndex)", items: subItems)
                duplicateGroups.append(group)
                groupIndex += 1
            }
            
            processedCandidates += 1.0
            if totalCandidates > 0 {
                let progress = 0.5 + (processedCandidates / totalCandidates * 0.5)
                progressHandler(progress)
            }
        }
        
        progressHandler(1.0)
        return duplicateGroups
    }
    
    /// Finds exact duplicate videos grouped by file size, duration, and dimensions
    func findDuplicateVideos(from assets: [PHAsset], progressHandler: @Sendable (Double) -> Void) async -> [MediaGroup] {
        guard !assets.isEmpty else { return [] }
        
        var mediaItems: [MediaItem] = []
        let totalCount = Double(assets.count)
        
        for (index, asset) in assets.enumerated() {
            let size = PhotoLibraryManager.getFileSize(for: asset)
            let item = MediaItem(asset: asset, fileSize: size)
            mediaItems.append(item)
            
            if index % 25 == 0 || index == assets.count - 1 {
                let progress = Double(index + 1) / totalCount * 0.6
                progressHandler(progress)
            }
        }
        
        // Group by (fileSize, duration, width, height)
        var videoMap: [String: [MediaItem]] = [:]
        for item in mediaItems {
            let durationKey = Int(item.duration * 10) // 0.1s precision
            let key = "\(item.fileSize)_\(durationKey)_\(item.pixelWidth)_\(item.pixelHeight)"
            videoMap[key, default: []].append(item)
        }
        
        var duplicateGroups: [MediaGroup] = []
        var groupIndex = 1
        
        for (_, items) in videoMap where items.count > 1 {
            let group = MediaGroup(id: "dup_video_\(groupIndex)", items: items)
            duplicateGroups.append(group)
            groupIndex += 1
        }
        
        progressHandler(1.0)
        return duplicateGroups
    }
}
