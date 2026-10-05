import SwiftUI

struct StorageBadgeView: View {
    let text: String
    var icon: String? = nil
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2.bold())
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}
