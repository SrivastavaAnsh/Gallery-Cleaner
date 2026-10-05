import SwiftUI

struct GroupHeaderView: View {
    let groupIndex: Int
    let group: MediaGroup
    let accentColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Group \(groupIndex)")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text("(\(group.items.count) items)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StorageBadgeView(
                text: "Reclaim \(ByteFormatter.format(group.reclaimableSize))",
                icon: "arrow.down.circle.fill",
                color: accentColor
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
