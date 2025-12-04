import SwiftUI

@main
struct AppGestaoServicosApp: App {
    @StateObject private var store = OfflineStore()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(store)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
