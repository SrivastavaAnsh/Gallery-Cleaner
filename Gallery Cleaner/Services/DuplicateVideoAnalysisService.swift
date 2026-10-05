import Foundation
import Photos
import CryptoKit

actor DuplicateVideoAnalysisService {
    
    /// Finds exact duplicate videos using duration, dimensions, and file size pre-bucketing,
    /// followed by a strong content-based fingerprint for candidate matches.
    func findDuplicateVideos(from assets: [PHAsset], progressHandler: @Sendable (Double) -> Void) async -> [MediaGroup] {
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
            
            if index % 25 == 0 || index == assets.count - 1 {
                let progress = (Double(index + 1) / totalCount) * 0.3
                progressHandler(progress)
            }
        }
        
        // Step 2: Narrow down possible matches using (fileSize, duration, pixelWidth, pixelHeight)
        // Duration is evaluated with 0.01s precision (duration * 100)
        var candidateBuckets: [String: [MediaItem]] = [:]
        for item in mediaItems {
            let durationKey = Int(item.duration * 100)
            let bucketKey = "\(item.fileSize)_\(durationKey)_\(item.pixelWidth)_\(item.pixelHeight)"
            candidateBuckets[bucketKey, default: []].append(item)
        }
        
        // Filter out unique videos (buckets with only 1 item)
        let multiItemBuckets = candidateBuckets.filter { $0.value.count > 1 }
        
        guard !multiItemBuckets.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        // Step 3: Compute strong content fingerprint (SHA-256) ONLY for candidates in multi-item buckets
        var hashMap: [String: [MediaItem]] = [:]
        let candidateItems = multiItemBuckets.values.flatMap { $0 }
        let totalCandidates = Double(candidateItems.count)
        var processedCandidates = 0.0
        
        for item in candidateItems {
            if let contentHash = await computeVideoContentHash(for: item.asset) {
                let key = "\(item.fileSize)_\(contentHash)"
                hashMap[key, default: []].append(item)
            } else {
                // Fallback to exact duration + size key if binary data read is restricted
                let durationKey = Int(item.duration * 100)
                let timeStampKey = Int(item.creationDate?.timeIntervalSince1970 ?? 0)
                let fallbackKey = "\(item.fileSize)_\(durationKey)_\(item.pixelWidth)_\(item.pixelHeight)_\(timeStampKey)"
                hashMap[fallbackKey, default: []].append(item)
            }
            
            processedCandidates += 1.0
            let progress = 0.3 + (processedCandidates / totalCandidates * 0.65)
            progressHandler(progress)
        }
        
        // Step 4: Construct duplicate MediaGroups for exact content matches
        var duplicateGroups: [MediaGroup] = []
        var groupIndex = 1
        
        for (_, items) in hashMap where items.count > 1 {
            let group = MediaGroup(id: "dup_video_\(groupIndex)", items: items)
            duplicateGroups.append(group)
            groupIndex += 1
        }
        
        progressHandler(1.0)
        return duplicateGroups
    }
    
    /// Computes a strong content-based fingerprint for a video asset by sampling resource binary bytes
    private func computeVideoContentHash(for asset: PHAsset) async -> String? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .video || $0.type == .pairedVideo }) ?? resources.first else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let resourceManager = PHAssetResourceManager.default()
            var sampleData = Data()
            let maxBytesToRead = 512 * 1024 // 512 KB sample buffer for fast & robust video fingerprinting
            
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            resourceManager.requestData(for: resource, options: options, dataReceivedHandler: { data in
                if sampleData.count < maxBytesToRead {
                    let needed = maxBytesToRead - sampleData.count
                    let bytesToAppend = data.prefix(needed)
                    sampleData.append(bytesToAppend)
                }
            }, completionHandler: { error in
                if sampleData.isEmpty || error != nil {
                    continuation.resume(returning: nil)
                } else {
                    let digest = SHA256.hash(data: sampleData)
                    let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()
                    continuation.resume(returning: hashString)
                }
            })
        }
    }
}
