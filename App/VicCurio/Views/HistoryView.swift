//
//  HistoryView.swift
//  VicCurio
//
//  Browse artifacts from the past 14 days.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    private var feedService: FeedService { FeedService.shared }

    @State private var recentItems: [CuriosityItem] = []
    @State private var isLoading = true
    @State private var selectedItem: CuriosityItem?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recentItems.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "clock",
                        description: Text("Check back after a few days!")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(recentItems) { item in
                                HistoryCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            .task {
                await loadHistory()
            }
            .refreshable {
                await loadHistory()
            }
        }
    }

    private func loadHistory() async {
        isLoading = true
        do {
            recentItems = try await feedService.fetchRecentItems(
                days: Constants.historyDays,
                modelContext: modelContext
            )
        } catch {
            // Keep existing items if refresh fails
        }
        isLoading = false
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
