//
//  FibonacciApp.swift
//  Fibonacci
//
//  Created by Niels Weggeman on 22/04/2026.
//

import SwiftUI
import CoreData

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

/// Routes between the start menu and the active game.
struct ContentRouter: View {
    @State private var activeSettings: GameSettings? = nil

    var body: some View {
        if let settings = activeSettings {
            GameView(settings: settings, onReturnToMenu: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeSettings = nil
                }
            })
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal:   .move(edge: .trailing)
            ))
        } else {
            MenuView(onStart: { settings in
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeSettings = settings
                }
            })
            .transition(.asymmetric(
                insertion: .move(edge: .leading),
                removal:   .move(edge: .leading)
            ))
        }
    }
}
