//
//  HistoryView.swift
//  VicCurio
//
//  Browse artifacts from the past 14 days.
//  Uses NavigationSplitView for adaptive layout on iPad.
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
        NavigationSplitView {
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
                    List(recentItems, selection: $selectedItem) { item in
                        HistoryRow(item: item, modelContext: modelContext)
                            .tag(item)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .refreshable {
                await loadHistory()
            }
        } detail: {
            if let item = selectedItem {
                ItemDetailContent(item: item)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "clock",
                    description: Text("Choose an item from history to view details.")
                )
            }
        }
        .task {
            await loadHistory()
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

// MARK: - History Row

struct HistoryRow: View {
    let item: CuriosityItem
    let modelContext: ModelContext

    @State private var isFavourite = false

    private var favouritesService: FavouritesService {
        FavouritesService(modelContext: modelContext)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: item.thumbnailUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                if item.isMineralMonday {
                    MineralMondayBadge(compact: true)
                }

                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(item.displayDateFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isFavourite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                isFavourite.toggle()
                favouritesService.toggleFavourite(for: item)
            } label: {
                Label(
                    isFavourite ? "Unfavourite" : "Favourite",
                    systemImage: isFavourite ? "heart.slash" : "heart"
                )
            }
            .tint(isFavourite ? .gray : .red)
        }
        .onAppear {
            isFavourite = favouritesService.isFavourite(item)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
