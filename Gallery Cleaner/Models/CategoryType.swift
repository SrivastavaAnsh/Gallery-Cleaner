import SwiftUI

enum CategoryType: String, CaseIterable, Identifiable, Hashable {
    case screenshots
    case videos
    case duplicatePhotos
    case similarPhotos
    case duplicateVideos
    case largeVideos
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .screenshots: return "Screenshots"
        case .videos: return "Videos"
        case .duplicatePhotos: return "Duplicate Photos"
        case .similarPhotos: return "Similar Photos"
        case .duplicateVideos: return "Duplicate Videos"
        case .largeVideos: return "Large Videos"
        }
    }
    
    var subtitle: String {
        switch self {
        case .screenshots: return "Screen grabs and snapshots"
        case .videos: return "All video recordings"
        case .duplicatePhotos: return "Exact photo copies"
        case .similarPhotos: return "Photos looking nearly identical"
        case .duplicateVideos: return "Exact video copies"
        case .largeVideos: return "Videos taking up most storage"
        }
    }
    
    var iconName: String {
        switch self {
        case .screenshots: return "crop"
        case .videos: return "video.fill"
        case .duplicatePhotos: return "square.on.square.fill"
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .duplicateVideos: return "film.stack.fill"
        case .largeVideos: return "externaldrive.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .screenshots: return .blue
        case .videos: return .purple
        case .duplicatePhotos: return .orange
        case .similarPhotos: return .pink
        case .duplicateVideos: return .red
        case .largeVideos: return .indigo
        }
    }
}
