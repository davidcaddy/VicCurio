//
//  VicCurioApp.swift
//  VicCurio
//
//  Created by David Caddy on 27/1/2026.
//

import SwiftUI
import SwiftData

@main
struct VicCurioApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PersistedItem.self,
            CachedFeed.self,
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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == Constants.urlScheme,
              url.host == "item" else { return }

        let itemId = url.pathComponents.dropFirst().joined(separator: "/")
        // Post notification to navigate to item detail
        NotificationCenter.default.post(
            name: .openItemDetail,
            object: itemId
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let openItemDetail = Notification.Name("openItemDetail")
}
