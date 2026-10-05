import Foundation
import Photos
import Vision
import UIKit

actor SimilarPhotoAnalysisService {
    
    /// Configurable threshold for Vision feature print distance comparison.
    /// Lower values require higher visual similarity; higher values allow more variation.
    var similarityThreshold: Float
    
    init(similarityThreshold: Float = 12.0) {
        self.similarityThreshold = similarityThreshold
    }
    
    private struct FeaturePrintHolder {
        let item: MediaItem
        let featurePrint: VNFeaturePrintObservation
    }
    
    /// Detects photos that are visually similar (excluding exact duplicates) using Apple's Vision framework.
    func findSimilarPhotos(
        from assets: [PHAsset],
        exactDuplicateIDs: Set<String> = [],
        customThreshold: Float? = nil,
        progressHandler: @Sendable (Double) -> Void
    ) async -> [MediaGroup] {
        guard !assets.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        let threshold = customThreshold ?? self.similarityThreshold
        
        // Filter out photos already identified as exact duplicates
        let candidateAssets = assets.filter { !exactDuplicateIDs.contains($0.localIdentifier) }
        guard !candidateAssets.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        // Step 1: Pre-filter candidate photos by creation time proximity (shots within 60s of each other)
        let sortedAssets = candidateAssets.sorted {
            ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast)
        }
        
        var candidateClusters: [[PHAsset]] = []
        var currentCluster: [PHAsset] = []
        
        for asset in sortedAssets {
            guard let currentDate = asset.creationDate else { continue }
            
            if let lastAsset = currentCluster.last, let lastDate = lastAsset.creationDate {
                let timeDifference = abs(currentDate.timeIntervalSince(lastDate))
                if timeDifference <= 60 { // Within 60 seconds
                    currentCluster.append(asset)
                } else {
                    if currentCluster.count > 1 {
                        candidateClusters.append(currentCluster)
                    }
                    currentCluster = [asset]
                }
            } else {
                currentCluster = [asset]
            }
        }
        
        if currentCluster.count > 1 {
            candidateClusters.append(currentCluster)
        }
        
        guard !candidateClusters.isEmpty else {
            progressHandler(1.0)
            return []
        }
        
        // Step 2: Asynchronously extract Vision feature prints using appropriately sized image representations (300x300)
        var resultGroups: [MediaGroup] = []
        var groupIndex = 1
        
        let totalCandidateCount = Double(candidateClusters.reduce(0) { $0 + $1.count })
        var processedCount = 0.0
        
        for cluster in candidateClusters {
            var featureHolders: [FeaturePrintHolder] = []
            
            for asset in cluster {
                let fileSize = PhotoLibraryManager.getFileSize(for: asset)
                let item = MediaItem(asset: asset, fileSize: fileSize)
                
                if let featurePrint = await extractFeaturePrintAsync(for: asset) {
                    featureHolders.append(FeaturePrintHolder(item: item, featurePrint: featurePrint))
                }
                
                processedCount += 1.0
                if totalCandidateCount > 0 {
                    progressHandler(processedCount / totalCandidateCount * 0.7)
                }
            }
            
            // Step 3: Compare feature print distances to create visually similar groups
            var visited = Set<String>()
            
            for i in 0..<featureHolders.count {
                let holderA = featureHolders[i]
                if visited.contains(holderA.item.id) { continue }
                
                var similarGroupItems = [holderA.item]
                
                for j in (i + 1)..<featureHolders.count {
                    let holderB = featureHolders[j]
                    if visited.contains(holderB.item.id) { continue }
                    
                    var distance: Float = 0.0
                    do {
                        try holderA.featurePrint.computeDistance(&distance, to: holderB.featurePrint)
                        // Ignore exact duplicates (distance near 0) and compare within configurable threshold
                        if distance > 0.05 && distance < threshold {
                            similarGroupItems.append(holderB.item)
                            visited.insert(holderB.item.id)
                        }
                    } catch {
                        // Ignore Vision distance error
                    }
                }
                
                if similarGroupItems.count > 1 {
                    visited.insert(holderA.item.id)
                    let group = MediaGroup(id: "similar_photo_\(groupIndex)", items: similarGroupItems)
                    resultGroups.append(group)
                    groupIndex += 1
                }
            }
        }
        
        progressHandler(1.0)
        return resultGroups
    }
    
    /// Asynchronously fetches an appropriately sized thumbnail representation (300x300) and computes Vision feature print
    private func extractFeaturePrintAsync(for asset: PHAsset) async -> VNFeaturePrintObservation? {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: 300, height: 300)
        
        return await withCheckedContinuation { continuation in
            var didResume = false
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }
                guard !didResume else { return }
                didResume = true
                
                guard let cgImage = image?.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                    let observation = request.results?.first as? VNFeaturePrintObservation
                    continuation.resume(returning: observation)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
