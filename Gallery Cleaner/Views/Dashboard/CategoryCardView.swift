import SwiftUI

struct CategoryCardView: View {
    let category: CategoryType
    let itemCount: Int?
    let sizeBytes: Int64?
    let isLoading: Bool
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Icon Circle + Storage Size Badge
            HStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.accentColor : category.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.iconName)
                        .font(.title3.bold())
                        .foregroundColor(isSelected ? .white : category.accentColor)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let size = sizeBytes, size > 0 {
                    StorageBadgeView(text: ByteFormatter.format(size), color: category.accentColor)
                }
            }
            
            // Headline Title ONLY (Secondary subtitle text removed)
            HStack(spacing: 6) {
                Text(category.title)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                
                if isSelected {
                    Circle()
                        .fill(category.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer(minLength: 0)
            
            // Bottom Row: Item Count + Arrow Chevron
            HStack {
                if let count = itemCount {
                    Text("\(count) items")
                        .font(.caption.bold())
                        .foregroundColor(isSelected ? category.accentColor : category.accentColor.opacity(0.9))
                } else {
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? category.accentColor : .secondary.opacity(0.6))
            }
        }
        .padding(16)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? category.accentColor.opacity(0.12) : Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? category.accentColor : Color.clear, lineWidth: 2.5)
        )
        .shadow(color: isSelected ? category.accentColor.opacity(0.3) : Color.black.opacity(0.04), radius: isSelected ? 8 : 4, x: 0, y: 4)
    }
}
