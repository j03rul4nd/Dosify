//
//  DosifyApp.swift
//  Dosify
//
//  Created by Ricardo Abraham Benitez Ruiz on 11/3/26.
//

import SwiftUI
import SwiftData

@main
struct DosifyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProgress.self,
            QuestionHistory.self,
            FavoriteDrug.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
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
