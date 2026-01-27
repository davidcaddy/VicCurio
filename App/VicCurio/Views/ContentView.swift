//
//  ContentView.swift
//  VicCurio
//
//  Main app view with tab navigation.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(1)

            FavouritesView()
                .tabItem {
                    Label("Favourites", systemImage: "heart")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
