import Foundation
import Photos
import UIKit
import Combine

final class PhotoLibraryManager: ObservableObject {
    static let shared = PhotoLibraryManager()
    
    @Published var permissionService = PhotoPermissionService.shared
    
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func checkAuthorization() {
        permissionService.updatePermissionState()
    }
    
    func requestAuthorization() async -> Bool {
        let state = await permissionService.requestPermissionIfNeeded()
        return state.canReadGallery
    }
    
    // MARK: - Asset Fetching
    
    func fetchScreenshots() -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
    
    func fetchAllVideos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .video, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
    
    func fetchAllPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            // Exclude live photos or burst if desired, keep standard photos
            assets.append(asset)
        }
        return assets
    }
    
    // MARK: - File Size Extraction
    
    nonisolated static func getFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return 0 }
        if let fileSizeNumber = resource.value(forKey: "fileSize") as? NSNumber {
            return fileSizeNumber.int64Value
        }
        return 0
    }
    
    // MARK: - Asset Deletion
    
    func deleteAssets(_ assets: [PHAsset]) async throws -> Bool {
        guard !assets.isEmpty else { return true }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
