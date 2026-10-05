import UIKit
import Photos
import SwiftUI

final class ImageCacheManager: @unchecked Sendable {
    static let shared = ImageCacheManager()
    
    private let cachingManager = PHCachingImageManager()
    
    init() {
        cachingManager.allowsCachingHighQualityImages = false
    }
    
    func requestThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 250, height: 250), completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        return cachingManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func cancelRequest(_ requestID: PHImageRequestID) {
        cachingManager.cancelImageRequest(requestID)
    }
    
    func startCaching(assets: [PHAsset], targetSize: CGSize = CGSize(width: 250, height: 250)) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        cachingManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: options)
    }
    
    func stopCaching(assets: [PHAsset], targetSize: CGSize = CGSize(width: 250, height: 250)) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        cachingManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: options)
    }
}
