import SwiftUI

struct PermissionStateView: View {
    @ObservedObject var permissionService: PhotoPermissionService = .shared
    let onPermissionGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 64, height: 64)
                
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundColor(iconColor)
            }
            
            VStack(spacing: 6) {
                Text(permissionService.permissionState.statusTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(permissionService.permissionState.statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            
            actionButton
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch permissionService.permissionState {
        case .notDetermined:
            Button(action: {
                Task {
                    let state = await permissionService.requestPermissionIfNeeded()
                    if state.canReadGallery {
                        onPermissionGranted()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Grant Access")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
        case .denied:
            Button(action: {
                permissionService.openAppSettings()
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(12)
            }
            
        case .limited:
            HStack(spacing: 12) {
                Button(action: {
                    permissionService.presentLimitedLibraryPicker()
                }) {
                    Text("Manage Selection")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: {
                    permissionService.openAppSettings()
                }) {
                    Text("Grant Full Access")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
        case .restricted:
            EmptyView()
            
        case .authorized:
            EmptyView()
        }
    }
    
    private var iconName: String {
        switch permissionService.permissionState {
        case .notDetermined: return "photo.stack.fill"
        case .authorized: return "checkmark.seal.fill"
        case .limited: return "photo.badge.checkmark"
        case .denied: return "exclamationmark.shield.fill"
        case .restricted: return "lock.shield.fill"
        }
    }
    
    private var iconColor: Color {
        switch permissionService.permissionState {
        case .notDetermined: return .blue
        case .authorized: return .green
        case .limited: return .orange
        case .denied: return .red
        case .restricted: return .gray
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
}
