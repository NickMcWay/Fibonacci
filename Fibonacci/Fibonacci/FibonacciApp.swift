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

    var body: some Scene {
        WindowGroup {
            GameView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
