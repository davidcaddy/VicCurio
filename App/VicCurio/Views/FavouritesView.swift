//
//  FavouritesView.swift
//  VicCurio
//
//  View saved favourite artifacts.
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
        NavigationStack {
            Group {
                if favouriteItems.isEmpty {
                    ContentUnavailableView(
                        "No Favourites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any artifact to save it here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favouriteItems) { persisted in
                                let item = persisted.toCuriosityItem()
                                FavouriteCard(item: item, favouritedAt: persisted.favouritedAt)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favourites")
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
    }
}

// MARK: - Favourite Card

struct FavouriteCard: View {
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
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(item.title)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                if item.isMineralMonday {
                    MineralMondayBadge(compact: true)
                }

                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let location = item.location, location.showOnMap {
                    Label(location.name, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if let date = favouritedAt {
                    Text("Saved \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "heart.fill")
                .font(.body)
                .foregroundStyle(.red)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FavouritesView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
