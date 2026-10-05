import SwiftUI

struct CategoryDetailView: View {
    @ObservedObject var viewModel: CategoryDetailViewModel
    var onSelectCategory: ((CategoryType) -> Void)? = nil
    @State private var showDeleteConfirmation = false
    
    // Fixed 3-column grid preserving large image tile sizes
    let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Quick Selection Action Bar (Shown when items/groups exist)
            if !viewModel.items.isEmpty || !viewModel.groups.isEmpty {
                HStack {
                    Button(action: {
                        if viewModel.totalSelectedCount > 0 {
                            viewModel.deselectAll()
                        } else {
                            viewModel.selectAll()
                        }
                    }) {
                        Text(viewModel.totalSelectedCount > 0 ? "Deselect All" : "Select All")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if !viewModel.groups.isEmpty {
                        Button(action: {
                            viewModel.autoSelectDuplicates()
                        }) {
                            Label("Keep Best", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                Divider()
            }
            
            // Grid & States Content
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Permission Error State
                    if !viewModel.isAuthorized {
                        PermissionStateView(permissionService: PhotoPermissionService.shared) {
                            // Permission granted action
                        }
                        .padding(.top, 40)
                    }
                    
                    // Custom Error State
                    else if let errorMsg = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                            
                            Text("Unable to Load Items")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.top, 40)
                    }
                    
                    // Loading State
                    else if viewModel.isScanning && viewModel.items.isEmpty && viewModel.groups.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(viewModel.category.accentColor)
                            
                            Text("Scanning \(viewModel.category.title)...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Analyzing photo library items. Please wait.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.top, 40)
                    }
                    
                    // Grouped View (Duplicates / Similar Photos)
                    else if !viewModel.groups.isEmpty {
                        ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { gIndex, group in
                            VStack(alignment: .leading, spacing: 8) {
                                GroupHeaderView(groupIndex: gIndex + 1, group: group, accentColor: viewModel.category.accentColor)
                                
                                LazyVGrid(columns: gridColumns, spacing: 8) {
                                    ForEach(group.items) { item in
                                        MediaItemCell(
                                            item: item,
                                            onToggleSelect: {
                                                viewModel.toggleSelection(for: item.id)
                                            },
                                            onPreview: {
                                                viewModel.selectedPreviewItem = item
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Flat Grid View (Screenshots / Videos / Large Videos)
                    else if !viewModel.items.isEmpty {
                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(viewModel.items) { item in
                                MediaItemCell(
                                    item: item,
                                    onToggleSelect: {
                                        viewModel.toggleSelection(for: item.id)
                                    },
                                    onPreview: {
                                        viewModel.selectedPreviewItem = item
                                    }
                                )
                            }
                        }
                    }
                    
                    // Empty State
                    else {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("No Items Found")
                                .font(.headline)
                            Text("Your gallery is clean in this category!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(12)
            }
            
            // Bottom Sticky Delete Bar
            if viewModel.totalSelectedCount > 0 {
                VStack(spacing: 8) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.totalSelectedCount) items selected")
                                .font(.headline)
                            Text("Free up \(ByteFormatter.format(viewModel.totalSelectedBytes))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(14)
                        }
                        .disabled(viewModel.isDeleting)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(CategoryType.allCases) { cat in
                        Button(action: {
                            onSelectCategory?(cat)
                        }) {
                            Label(cat.title, systemImage: cat.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.category.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(item: $viewModel.selectedPreviewItem) { item in
            AssetPreviewModal(item: item)
        }
        .alert("Delete Selected Items?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deleteSelectedAssets()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These items will be moved to Recently Deleted in your Photos app.")
        }
    }
}
