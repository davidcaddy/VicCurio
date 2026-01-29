//
//  FavouritesView.swift
//  VicCurio
//
//  View saved favourite artifacts.
//  Uses NavigationSplitView for adaptive layout on iPad.
//

import SwiftUI
import SwiftData

struct FavouritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<PersistedItem> { $0.isFavourite == true },
        sort: \PersistedItem.favouritedAt,
        order: .reverse
    ) private var favouriteItems: [PersistedItem]

    @State private var selectedItem: CuriosityItem?

    var body: some View {
        NavigationSplitView {
            Group {
                if favouriteItems.isEmpty {
                    ContentUnavailableView(
                        "No Favourites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any artifact to save it here.")
                    )
                } else {
                    List(favouriteItems, selection: $selectedItem) { persisted in
                        let item = persisted.toCuriosityItem()
                        FavouriteRow(item: item, favouritedAt: persisted.favouritedAt)
                            .tag(item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if selectedItem?.id == item.id {
                                        selectedItem = nil
                                    }
                                    FavouritesService(modelContext: modelContext).toggleFavourite(for: item)
                                } label: {
                                    Label("Unfavourite", systemImage: "heart.slash")
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favourites")
        } detail: {
            if let item = selectedItem {
                ItemDetailContent(item: item)
            } else {
                ContentUnavailableView(
                    "Select a Favourite",
                    systemImage: "heart",
                    description: Text("Choose a favourite to view details.")
                )
            }
        }
    }
}

// MARK: - Favourite Row

struct FavouriteRow: View {
    let item: CuriosityItem
    let favouritedAt: Date?

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

                if let location = item.location, location.shouldShowOnMap {
                    Label(location.displayName, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let date = favouritedAt {
                    Text("Saved \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "heart.fill")
                .font(.body)
                .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavouritesView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
