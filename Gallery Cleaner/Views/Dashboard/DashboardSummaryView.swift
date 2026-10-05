import SwiftUI

struct DashboardSummaryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onSelectCategory: (CategoryType) -> Void
    
    let gridColumns = [
        GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Welcome / Hero Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GALLERY OVERVIEW")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                                .tracking(1.2)
                            
                            Text("Reclaimable Storage")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await viewModel.startScan()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Rescan")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isScanning || !viewModel.isAuthorized)
                    }
                    
                    Text("Select any category below or from the sidebar to inspect items, remove unnecessary files, and free up space.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Hero Reclaimable Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TOTAL CLEANABLE SPACE")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        
                        Text(ByteFormatter.format(viewModel.totalReclaimableBytes))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if viewModel.isScanning {
                            Text(viewModel.scanStatusText)
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("Scan completed successfully")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(24)
                
                if viewModel.isScanning {
                    LoadingProgressView(progress: viewModel.scanProgress, statusText: viewModel.scanStatusText)
                }
                
                // Categories Overview Grid
                VStack(alignment: .leading, spacing: 14) {
                    Text("Category Breakdown")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(CategoryType.allCases) { category in
                            Button(action: {
                                onSelectCategory(category)
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(category.accentColor.opacity(0.15))
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: category.iconName)
                                            .font(.title3.bold())
                                            .foregroundColor(category.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let count = viewModel.categoryCounts[category] {
                                            Text("\(count) items")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Scanning...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let size = viewModel.categorySizes[category], size > 0 {
                                        StorageBadgeView(text: ByteFormatter.format(size), color: category.accentColor)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(16)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Cleanup Tip Banner
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Cleanup Tip")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Duplicate Photos and Large Videos usually account for the largest space savings. Review those first!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(18)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(20)
            }
            .padding(24)
        }
        .refreshable {
            await viewModel.startScan()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}
