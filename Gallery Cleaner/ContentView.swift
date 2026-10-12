import SwiftUI

@main 
struct SwoopApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    DashboardView()
}

