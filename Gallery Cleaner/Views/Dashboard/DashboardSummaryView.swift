import SwiftUI

struct DashboardSummaryView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onSelectCategory: (CategoryType) -> Void
    
    // 2-column flex grid matching Image 2 layout
    let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
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
                        Text("TOTAL RECLAIMABLE SPACE")
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
                
                // Categories Overview Grid (2 Columns matching Image 2)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Category Breakdown")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(CategoryType.allCases) { category in
                            Button(action: {
                                onSelectCategory(category)
                            }) {
                                CategoryCardView(
                                    category: category,
                                    itemCount: viewModel.categoryCounts[category],
                                    sizeBytes: viewModel.categorySizes[category],
                                    isLoading: viewModel.isScanning && (viewModel.categoryCounts[category] == nil),
                                    isSelected: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .refreshable {
            await viewModel.startScan()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}
