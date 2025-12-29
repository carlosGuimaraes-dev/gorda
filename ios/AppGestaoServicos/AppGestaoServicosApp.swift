import SwiftUI

@main
struct AppGestaoServicosApp: App {
    @StateObject private var store = OfflineStore()
    private let persistenceController = PersistenceController.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                showSplash = false
                            }
                        }
                } else {
                    if store.session != nil {
                        HomeView()
                    } else {
                        LoginView()
                    }
                }
            }
            .environmentObject(store)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.locale, store.appPreferences.language.locale)
            .tint(AppTheme.primary)
        }
    }
}
