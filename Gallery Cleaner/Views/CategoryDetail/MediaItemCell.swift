import SwiftUI
import Photos

struct MediaItemCell: View {
    let item: MediaItem
    let onToggleSelect: () -> Void
    let onPreview: () -> Void
    
    @State private var thumbnail: UIImage? = nil
    @State private var requestID: PHImageRequestID? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView().scaleEffect(0.7))
                    }
                    
                    // Size Badge & Duration Badge
                    VStack(alignment: .leading, spacing: 2) {
                        if let duration = item.formattedDuration {
                            Text(duration)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                        }
                        
                        Text(item.formattedSize)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .padding(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onPreview()
            }
            
            // Selection Checkmark Circle
            Button(action: onToggleSelect) {
                ZStack {
                    Circle()
                        .fill(item.isSelected ? Color.blue : Color.black.opacity(0.4))
                        .frame(width: 28, height: 28)
                    
                    if item.isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(8)
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            if let id = requestID {
                ImageCacheManager.shared.cancelRequest(id)
            }
        }
    }
    
    private func loadThumbnail() {
        requestID = ImageCacheManager.shared.requestThumbnail(for: item.asset) { img in
            self.thumbnail = img
        }
    }
}
