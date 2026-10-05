import SwiftUI

struct LoadingProgressView: View {
    let progress: Double
    let statusText: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .clipShape(Capsule())
            
            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
