import SwiftUI
import CoreData
import Combine

@main
struct FibonacciApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var audio = AudioManager()

    var body: some Scene {
        WindowGroup {
            ContentRouter()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(audio)
        }
    }
}

// Routes between the menu and the active game.
struct ContentRouter: View {
    @State private var activeSettings: GameSettings? = nil
    @AppStorage("SlideWords_DarkMode")       private var darkMode: Bool = false
    @AppStorage("SlideWords_HasSeenTutorial") private var hasSeenTutorial: Bool = false

    var body: some View {
        Group {
            if let settings = activeSettings {
                GameView(settings: settings, onReturnToMenu: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeSettings = nil
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal:   .move(edge: .trailing)
                ))
            } else {
                MenuView(onStart: { settings in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeSettings = settings
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal:   .move(edge: .leading)
                ))
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .fullScreenCover(isPresented: .init(
            get: { !hasSeenTutorial },
            set: { if !$0 { hasSeenTutorial = true } }
        )) {
            TutorialView(onDismiss: { hasSeenTutorial = true })
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
