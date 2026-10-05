import Foundation
import Photos
import CryptoKit

actor DuplicatePhotoAnalysisService {
    
    /// Finds exact duplicate photos using metadata pre-bucketing and content-based SHA-256 fingerprinting.
    /// Does NOT compare every photo against every other photo unnecessarily.
    func findDuplicatePhotos(from assets: [PHAsset], progressHandler: @Sendable (Double) -> Void) async -> [MediaGroup] {
        guard !assets.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        let totalCount = Double(assets.count)
        var mediaItems: [MediaItem] = []
        
        // Step 1: Pre-fetch file size and wrap in MediaItem
        for (index, asset) in assets.enumerated() {
            let size = PhotoLibraryManager.getFileSize(for: asset)
            let item = MediaItem(asset: asset, fileSize: size)
            mediaItems.append(item)
            
            if index % 50 == 0 || index == assets.count - 1 {
                let progress = (Double(index + 1) / totalCount) * 0.3
                progressHandler(progress)
            }
        }
        
        // Step 2: Pre-bucket photos by (fileSize, pixelWidth, pixelHeight)
        // Photos with different size or resolution cannot be exact copies.
        // This avoids loading/hashing image content for unique photos.
        var candidateBuckets: [String: [MediaItem]] = [:]
        for item in mediaItems {
            let bucketKey = "\(item.fileSize)_\(item.pixelWidth)_\(item.pixelHeight)"
            candidateBuckets[bucketKey, default: []].append(item)
        }
        
        // Only keep buckets containing 2 or more candidate photos
        let multiItemBuckets = candidateBuckets.filter { $0.value.count > 1 }
        
        guard !multiItemBuckets.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        // Step 3: Compute content-based fingerprint hash (SHA-256) ONLY for candidates in multi-item buckets
        var hashMap: [String: [MediaItem]] = [:]
        let candidateItems = multiItemBuckets.values.flatMap { $0 }
        let totalCandidates = Double(candidateItems.count)
        var processedCandidates = 0.0
        
        for item in candidateItems {
            if let contentHash = await computeContentHash(for: item.asset) {
                let key = "\(item.fileSize)_\(contentHash)"
                hashMap[key, default: []].append(item)
            } else {
                // Fallback to size + timestamp key if binary data read is restricted
                let timeStampKey = Int(item.creationDate?.timeIntervalSince1970 ?? 0)
                let fallbackKey = "\(item.fileSize)_\(item.pixelWidth)_\(item.pixelHeight)_\(timeStampKey)"
                hashMap[fallbackKey, default: []].append(item)
            }
            
            processedCandidates += 1.0
            let progress = 0.3 + (processedCandidates / totalCandidates * 0.65)
            progressHandler(progress)
        }
        
        // Step 4: Construct duplicate MediaGroups for exact hash matches
        var duplicateGroups: [MediaGroup] = []
        var groupIndex = 1
        
        for (_, items) in hashMap where items.count > 1 {
            let group = MediaGroup(id: "dup_photo_\(groupIndex)", items: items)
            duplicateGroups.append(group)
            groupIndex += 1
        }
        
        progressHandler(1.0)
        return duplicateGroups
    }
    
    /// Generates a SHA-256 content-based fingerprint for a photo's binary image data
    private func computeContentHash(for asset: PHAsset) async -> String? {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .none
        
        return await withCheckedContinuation { continuation in
            manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data = data, !data.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let digest = SHA256.hash(data: data)
                let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()
                continuation.resume(returning: hashString)
            }
        }
    }
}
