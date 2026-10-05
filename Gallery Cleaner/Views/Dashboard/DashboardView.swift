import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedCategory: CategoryType? = nil
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    
    // 1 card per row in sidebar
    let sidebarColumns = [
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            sidebarContent
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Gallery Cleaner")
                .navigationBarTitleDisplayMode(.large)
        } detail: {
            if let category = selectedCategory {
                destinationView(for: category)
                    .id(category)
            } else {
                DashboardSummaryView(
                    viewModel: viewModel,
                    onSelectCategory: { category in
                        selectCategory(category)
                    }
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await viewModel.checkAndRequestPermissionOnLaunch()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.permissionService.updatePermissionState()
            }
        }
    }
    
    private func selectCategory(_ category: CategoryType) {
        selectedCategory = category
        preferredCompactColumn = .detail
    }
    
    private var sidebarContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                // Reclaimable Storage Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RECLAIMABLE SPACE")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            
                            Text(ByteFormatter.format(viewModel.totalReclaimableBytes))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await viewModel.startScan()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isScanning || !viewModel.isAuthorized)
                    }
                    
                    if viewModel.isScanning {
                        LoadingProgressView(progress: viewModel.scanProgress, statusText: viewModel.scanStatusText)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(24)
                
                // Permission Banner/Card if access is limited or denied
                if !viewModel.isAuthorized || viewModel.permissionService.permissionState.isLimited {
                    PermissionStateView(permissionService: viewModel.permissionService) {
                        Task {
                            await viewModel.startScan()
                        }
                    }
                }
                
                // 6 Categories List - 1 Card Per Row
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gallery Categories")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: sidebarColumns, spacing: 14) {
                        ForEach(CategoryType.allCases) { category in
                            Button(action: {
                                selectCategory(category)
                            }) {
                                CategoryCardView(
                                    category: category,
                                    itemCount: viewModel.categoryCounts[category],
                                    sizeBytes: viewModel.categorySizes[category],
                                    isLoading: viewModel.isScanning && (viewModel.categoryCounts[category] == nil),
                                    isSelected: selectedCategory == category
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!viewModel.isAuthorized)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func destinationView(for category: CategoryType) -> CategoryDetailView {
        let vm: CategoryDetailViewModel
        let deletionCallback: (Set<String>) -> Void = { deletedIDs in
            viewModel.handleAssetsDeleted(deletedIDs: deletedIDs)
        }
        
        switch category {
        case .screenshots:
            vm = CategoryDetailViewModel(
                category: category,
                items: viewModel.screenshots,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        case .videos:
            vm = CategoryDetailViewModel(
                category: category,
                items: viewModel.videos,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        case .duplicatePhotos:
            vm = CategoryDetailViewModel(
                category: category,
                groups: viewModel.duplicatePhotoGroups,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        case .similarPhotos:
            vm = CategoryDetailViewModel(
                category: category,
                groups: viewModel.similarPhotoGroups,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        case .duplicateVideos:
            vm = CategoryDetailViewModel(
                category: category,
                groups: viewModel.duplicateVideoGroups,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        case .largeVideos:
            vm = CategoryDetailViewModel(
                category: category,
                items: viewModel.largeVideos,
                isScanning: viewModel.isScanning,
                isAuthorized: viewModel.isAuthorized,
                onAssetsDeleted: deletionCallback
            )
        }
        
        return CategoryDetailView(
            viewModel: vm,
            onSelectCategory: { newCategory in
                selectedCategory = newCategory
            }
        )
    }
}
