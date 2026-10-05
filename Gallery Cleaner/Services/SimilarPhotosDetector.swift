import Foundation
import Photos
import Vision
import UIKit

actor SimilarPhotosDetector {
    
    private struct FeaturePrintHolder {
        let item: MediaItem
        let featurePrint: VNFeaturePrintObservation
    }
    
    /// Detects photos that look visually similar using Apple's Vision framework
    func findSimilarPhotos(from assets: [PHAsset], maxDistanceThreshold: Float = 12.0, progressHandler: @Sendable (Double) -> Void) async -> [MediaGroup] {
        guard !assets.isEmpty else { return [] }
        
        // Step 1: Pre-filter by time window proximity (shots taken within 60 seconds of each other)
        let sortedAssets = assets.sorted {
            ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast)
        }
        
        var candidateClusters: [[PHAsset]] = []
        var currentCluster: [PHAsset] = []
        
        for asset in sortedAssets {
            guard let currentDate = asset.creationDate else { continue }
            
            if let lastAsset = currentCluster.last, let lastDate = lastAsset.creationDate {
                let timeDifference = abs(currentDate.timeIntervalSince(lastDate))
                if timeDifference <= 60 { // within 60 seconds
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
        
        // Step 2: Compute Vision Feature Prints for candidate clusters
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .exact
        
        var resultGroups: [MediaGroup] = []
        var groupIndex = 1
        
        let totalCandidateCount = Double(candidateClusters.reduce(0) { $0 + $1.count })
        var processedCount = 0.0
        
        for cluster in candidateClusters {
            var featureHolders: [FeaturePrintHolder] = []
            
            for asset in cluster {
                let targetSize = CGSize(width: 300, height: 300)
                var cgImage: CGImage?
                
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                    cgImage = image?.cgImage
                }
                
                let fileSize = PhotoLibraryManager.getFileSize(for: asset)
                let item = MediaItem(asset: asset, fileSize: fileSize)
                
                if let cgImage = cgImage, let featurePrint = self.generateFeaturePrint(for: cgImage) {
                    featureHolders.append(FeaturePrintHolder(item: item, featurePrint: featurePrint))
                } else {
                    // Fallback holder
                    featureHolders.append(FeaturePrintHolder(item: item, featurePrint: VNFeaturePrintObservation()))
                }
                
                processedCount += 1.0
                if totalCandidateCount > 0 {
                    progressHandler(processedCount / totalCandidateCount)
                }
            }
            
            // Group items in cluster by distance threshold
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
                        if distance < maxDistanceThreshold {
                            similarGroupItems.append(holderB.item)
                            visited.insert(holderB.item.id)
                        }
                    } catch {
                        // Ignore vision distance error
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
    
    private nonisolated func generateFeaturePrint(for image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
}
