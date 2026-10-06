# 📱 Gallery Cleaner

A high-performance, privacy-focused native iOS app built with **SwiftUI**, **Photos (`PHPhotoLibrary`)**, **Vision Framework**, and **CryptoKit**. **Gallery Cleaner** scans your photo library to detect exact duplicate photos and videos, visually similar shots, screenshots, and large media files, helping users clean up device storage effortlessly.

---

## ✨ Key Features

* 📊 **Reclaimable Storage Calculation**: Instantly computes total wasted storage space and breakdown per category.
* ⚡ **Pull-to-Refresh & Rescan**: Drag down on any page or tap **Rescan** to perform a complete disk library re-analysis.
* 🛡 **Full & Limited Permission Support**: Gracefully handles iOS photo authorization states (`authorized`, `limited`, `denied`, `restricted`) with in-app settings guidance.
* ✨ **"Keep Best" Smart Selection**: Auto-selects redundant duplicate/similar items for deletion while preserving the newest / best photo untouched.
* 🗑 **Batch Deletion**: Safely removes selected assets from the device using native iOS Photo Library confirmation prompts.
* ⚡ **High-Speed Thumbnail Caching**: Instant rendering of media grids backed by `PHCachingImageManager` pre-caching.

---

## 🗂 Media Categories

| Category | Icon | Description | Detection Logic |
| :--- | :---: | :--- | :--- |
| **Screenshots** | ✂️ | Screen grabs and snapshots | Queries `PHAssetMediaSubtype.photoScreenshot` |
| **Videos** | 🎥 | All video recordings | Queries all `.video` media type assets sorted by date |
| **Duplicate Photos** | 👯 | Exact photo copies | Pre-bucketed by dimensions/size, then SHA-256 content fingerprinted |
| **Similar Photos** | 📸 | Visually similar shots | Clustered by 60s creation timestamp proximity + Apple Vision feature vector distance comparison |
| **Duplicate Videos** | 🎞 | Exact video copies | Pre-bucketed by duration/resolution/size, then 512KB sample buffer SHA-256 fingerprinted |
| **Large Videos** | 💾 | High storage impact videos | Video assets sorted descending by total disk file size |

---

## 🔬 Core Algorithms & Technical Breakdown

### 1. Exact Duplicate Photo Detection (`DuplicatePhotoAnalysisService.swift`)
* **Stage 1 (Pre-Bucketing)**: Photos are grouped into candidate buckets by `(fileSize, pixelWidth, pixelHeight)`. Single-item buckets are discarded without reading image data.
* **Stage 2 (SHA-256 Fingerprinting)**: Candidate assets compute SHA-256 binary hashes via `CryptoKit`. Items sharing matching hashes are grouped into duplicate sets.

### 2. Exact Duplicate Video Detection (`DuplicateVideoAnalysisService.swift`)
* **Stage 1 (Metadata Bucketing)**: Videos are bucketed by `(fileSize, duration, pixelWidth, pixelHeight)`.
* **Stage 2 (Sample Buffer Hash)**: Samples up to 512 KB of video resource bytes to quickly generate SHA-256 content fingerprints without reading multi-gigabyte video files.

### 3. Visual Similarity Detection (`SimilarPhotoAnalysisService.swift`)
* **Stage 1 (Timestamp Clustering)**: Photos are grouped into candidate clusters taken within 60 seconds of each other.
* **Stage 2 (Vision Feature Print Vectors)**: Generates `VNFeaturePrintObservation` representations using Apple's Vision framework.
* **Stage 3 (Distance Thresholding)**: Computes feature vector distance. Items with distance below configured threshold (e.g. 12.0) are grouped as visually similar shots.

---

## 📂 Architecture & Project Structure

The project follows the **MVVM (Model-View-ViewModel)** architectural pattern:

```text
Gallery Cleaner/
├── App/
│   └── ContentView.swift            # Main entry point & NavigationSplitView root
├── Models/
│   ├── MediaItem.swift              # PHAsset wrapper with metadata & selection state
│   ├── MediaGroup.swift             # Grouping model for duplicates & similar items
│   └── CategoryType.swift           # Category enum definition & UI theme attributes
├── ViewModels/
│   ├── DashboardViewModel.swift     # Core scanning engine & storage metrics publisher
│   └── CategoryDetailViewModel.swift# Category selection, batch deletion & smart defaults
├── Services/
│   ├── PhotoLibraryManager.swift    # Asset fetching & PHPhotoLibrary deletion engine
│   ├── PhotoPermissionService.swift # Observer for authorization states & settings link
│   ├── DuplicatePhotoAnalysisService.swift # SHA-256 photo fingerprinting
│   ├── DuplicateVideoAnalysisService.swift # Sample buffer SHA-256 video fingerprinting
│   └── SimilarPhotoAnalysisService.swift   # Apple Vision visual similarity engine
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift        # Split-view sidebar & dashboard container
│   │   ├── DashboardSummaryView.swift # Detailed overview grid & rescan header
│   │   └── CategoryCardView.swift     # Individual category statistics card
│   ├── CategoryDetail/
│   │   ├── CategoryDetailView.swift   # 3-column media grid with quick actions & sticky bar
│   │   ├── GroupHeaderView.swift      # Duplicate/Similar group header badge
│   │   └── MediaItemCell.swift        # High-performance grid cell with thumbnail loader
│   └── Components/
│       ├── StorageBadgeView.swift     # Storage indicator component
│       ├── LoadingProgressView.swift  # Scan status progress bar
│       ├── PermissionStateView.swift  # Authorization warning & call-to-action view
│       └── AssetPreviewModal.swift    # Fullscreen asset inspector modal
└── Utilities/
    ├── ImageCacheManager.swift       # PHCachingImageManager wrapper
    └── ByteFormatter.swift           # File size string formatting utility
```

---


## 🚀 Building & Running

1. Open `Gallery Cleaner.xcodeproj` in **Xcode**.
2. Select your target simulator or connected iOS/iPadOS device.
3. Press **Cmd + R** to build and run the application.
4. When prompted on first launch, grant **Photo Access** to allow library scanning.

---

## 🔒 Privacy & Security

Gallery Cleaner processes all photo data, binary hashing, and Vision feature vector computations **100% locally on device**. No media or personal telemetry is transmitted over the network.
