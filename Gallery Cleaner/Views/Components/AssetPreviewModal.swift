import SwiftUI
import Photos

struct AssetPreviewModal: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(item.formattedSize)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        if let date = item.creationDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: item.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { img, _ in
            self.image = img
        }
    }
}
