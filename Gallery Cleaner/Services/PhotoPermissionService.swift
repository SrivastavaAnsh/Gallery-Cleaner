import Foundation
import Photos
import PhotosUI
import UIKit
import Combine

enum PhotoPermissionState {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
    
    var canReadGallery: Bool {
        self == .authorized || self == .limited
    }
    
    var isLimited: Bool {
        self == .limited
    }
    
    var statusTitle: String {
        switch self {
        case .notDetermined: return "Photo Access Required"
        case .authorized: return "Full Access Granted"
        case .limited: return "Limited Access Granted"
        case .denied: return "Photo Access Denied"
        case .restricted: return "Photo Access Restricted"
        }
    }
    
    var statusDescription: String {
        switch self {
        case .notDetermined:
            return "Gallery Cleaner needs permission to scan your library for duplicate photos, videos, and screenshots to free up storage space."
        case .authorized:
            return "Full access allows complete detection of duplicate photos, videos, and large media files."
        case .limited:
            return "You granted limited photo access. Only selected photos can be scanned. For full gallery cleaning, grant Full Access in Settings."
        case .denied:
            return "Photo library access is turned off for Gallery Cleaner. Please enable access in iOS Settings to scan your photos."
        case .restricted:
            return "Photo library access is restricted on this device (e.g., due to parental controls or device policy)."
        }
    }
}

@MainActor
final class PhotoPermissionService: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    static let shared = PhotoPermissionService()
    
    @Published var permissionState: PhotoPermissionState = .notDetermined
    
    override private init() {
        super.init()
        updatePermissionState()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    /// Updates permission state based on system authorization status
    func updatePermissionState() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            self.permissionState = .notDetermined
        case .authorized:
            self.permissionState = .authorized
        case .limited:
            self.permissionState = .limited
        case .denied:
            self.permissionState = .denied
        case .restricted:
            self.permissionState = .restricted
        @unknown default:
            self.permissionState = .denied
        }
    }
    
    /// Requests access if not determined. Called automatically on first launch.
    @discardableResult
    func requestPermissionIfNeeded() async -> PhotoPermissionState {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            updatePermissionState()
            return permissionState
        } else {
            updatePermissionState()
            return permissionState
        }
    }
    
    /// Opens the iOS Settings app for Gallery Cleaner
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Presents the native limited photo library picker for modifying selected photos
    func presentLimitedLibraryPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootViewController)
    }
    
    let libraryDidChangePublisher = PassthroughSubject<Void, Never>()

    // MARK: - PHPhotoLibraryChangeObserver
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.updatePermissionState()
            self.libraryDidChangePublisher.send()
        }
    }
}
