import SwiftUI
import Photos
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var permissionService = PhotoPermissionService.shared
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var scanStatusText: String = "Ready to scan"
    
    // Category Counts & Sizes
    @Published var categoryCounts: [CategoryType: Int] = [:]
    @Published var categorySizes: [CategoryType: Int64] = [:]
    
    // Processed Items Cache
    @Published var screenshots: [MediaItem] = []
    @Published var videos: [MediaItem] = []
    @Published var duplicatePhotoGroups: [MediaGroup] = []
    @Published var similarPhotoGroups: [MediaGroup] = []
    @Published var duplicateVideoGroups: [MediaGroup] = []
    @Published var largeVideos: [MediaItem] = []
    
    private let photoManager = PhotoLibraryManager.shared
    private let duplicateDetector = DuplicateDetector()
    private let similarDetector = SimilarPhotosDetector()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        permissionService.$permissionState
            .sink { [weak self] state in
                guard let self = self else { return }
                if state.canReadGallery && self.screenshots.isEmpty && !self.isScanning {
                    Task {
                        await self.startScan()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    var isAuthorized: Bool {
        permissionService.permissionState.canReadGallery
    }
    
    var totalReclaimableBytes: Int64 {
        let dupPhotosReclaimable = duplicatePhotoGroups.reduce(0) { $0 + $1.reclaimableSize }
        let similarPhotosReclaimable = similarPhotoGroups.reduce(0) { $0 + $1.reclaimableSize }
        let dupVideosReclaimable = duplicateVideoGroups.reduce(0) { $0 + $1.reclaimableSize }
        let largeVideosSize = largeVideos.reduce(0) { $0 + $1.fileSize }
        return dupPhotosReclaimable + similarPhotosReclaimable + dupVideosReclaimable + (largeVideosSize / 2)
    }
    
    /// Requests permission if not determined upon opening the app
    func checkAndRequestPermissionOnLaunch() async {
        let state = await permissionService.requestPermissionIfNeeded()
        if state.canReadGallery {
            await startScan()
        }
    }
    
    func startScan() async {
        guard isAuthorized else { return }
        isScanning = true
        scanProgress = 0.0
        scanStatusText = "Scanning photo library..."
        
        // Step 1: Fetch Screenshots & Videos (Fast)
        scanStatusText = "Fetching screenshots and videos..."
        let screenshotAssets = photoManager.fetchScreenshots()
        let videoAssets = photoManager.fetchAllVideos()
        let photoAssets = photoManager.fetchAllPhotos()
        
        // Build Screenshots list
        let screenshotItems = screenshotAssets.map { MediaItem(asset: $0, fileSize: PhotoLibraryManager.getFileSize(for: $0)) }
        self.screenshots = screenshotItems
        self.categoryCounts[.screenshots] = screenshotItems.count
        self.categorySizes[.screenshots] = screenshotItems.reduce(0) { $0 + $1.fileSize }
        
        // Build Videos list & Large Videos
        let videoItems = videoAssets.map { MediaItem(asset: $0, fileSize: PhotoLibraryManager.getFileSize(for: $0)) }
        self.videos = videoItems
        self.categoryCounts[.videos] = videoItems.count
        self.categorySizes[.videos] = videoItems.reduce(0) { $0 + $1.fileSize }
        
        // Large Videos: sorted descending by storage size
        let sortedLarge = videoItems.sorted { $0.fileSize > $1.fileSize }
        self.largeVideos = Array(sortedLarge.prefix(50))
        self.categoryCounts[.largeVideos] = self.largeVideos.count
        self.categorySizes[.largeVideos] = self.largeVideos.reduce(0) { $0 + $1.fileSize }
        
        scanProgress = 0.3
        
        // Step 2: Background Duplicate Photo Detection
        scanStatusText = "Detecting duplicate photos..."
        let photoDupGroups = await duplicateDetector.findDuplicatePhotos(from: photoAssets) { [weak self] progress in
            Task { @MainActor in
                self?.scanProgress = 0.3 + (progress * 0.25)
            }
        }
        self.duplicatePhotoGroups = photoDupGroups
        self.categoryCounts[.duplicatePhotos] = photoDupGroups.reduce(0) { $0 + $1.items.count }
        self.categorySizes[.duplicatePhotos] = photoDupGroups.reduce(0) { $0 + $1.reclaimableSize }
        
        // Step 3: Background Duplicate Video Detection
        scanStatusText = "Detecting duplicate videos..."
        let videoDupGroups = await duplicateDetector.findDuplicateVideos(from: videoAssets) { [weak self] progress in
            Task { @MainActor in
                self?.scanProgress = 0.55 + (progress * 0.15)
            }
        }
        self.duplicateVideoGroups = videoDupGroups
        self.categoryCounts[.duplicateVideos] = videoDupGroups.reduce(0) { $0 + $1.items.count }
        self.categorySizes[.duplicateVideos] = videoDupGroups.reduce(0) { $0 + $1.reclaimableSize }
        
        // Step 4: Background Similar Photos Detection (Vision framework)
        scanStatusText = "Analyzing similar photos..."
        let simGroups = await similarDetector.findSimilarPhotos(from: photoAssets) { [weak self] progress in
            Task { @MainActor in
                self?.scanProgress = 0.70 + (progress * 0.30)
            }
        }
        self.similarPhotoGroups = simGroups
        self.categoryCounts[.similarPhotos] = simGroups.reduce(0) { $0 + $1.items.count }
        self.categorySizes[.similarPhotos] = simGroups.reduce(0) { $0 + $1.reclaimableSize }
        
        scanProgress = 1.0
        scanStatusText = "Scan complete!"
        isScanning = false
    }
}
