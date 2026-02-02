//
//  ExMindApp.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

@main
struct ExMindApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MindMapDocument.self,
            MindMapNode.self,
            NodeProperty.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log the detailed error for debugging
            print("❌ Failed to create ModelContainer: \(error)")
            
            // In development, you might want to try deleting the old store
            #if DEBUG
            if let error = error as? SwiftDataError {
                print("SwiftData Error Details: \(error)")
            }
            #endif
            
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
