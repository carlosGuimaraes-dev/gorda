import SwiftUI

@main
struct AppGestaoServicosApp: App {
    @StateObject private var store = OfflineStore()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(store)
        }
    }
}
