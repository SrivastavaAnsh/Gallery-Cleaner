import Foundation
import Photos
import SwiftUI

struct MediaItem: Identifiable, Hashable, @unchecked Sendable {
    let id: String
    let asset: PHAsset
    let fileSize: Int64
    let creationDate: Date?
    let duration: TimeInterval
    let pixelWidth: Int
    let pixelHeight: Int
    var isSelected: Bool = false
    
    init(asset: PHAsset, fileSize: Int64 = 0) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.fileSize = fileSize
        self.creationDate = asset.creationDate
        self.duration = asset.duration
        self.pixelWidth = asset.pixelWidth
        self.pixelHeight = asset.pixelHeight
        self.isSelected = false
    }
    
    var formattedSize: String {
        ByteFormatter.format(fileSize)
    }
    
    var formattedDuration: String? {
        guard asset.mediaType == .video, duration > 0 else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id && lhs.isSelected == rhs.isSelected
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isSelected)
    }
}
