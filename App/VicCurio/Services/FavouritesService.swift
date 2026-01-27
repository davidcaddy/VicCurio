//
//  FavouritesService.swift
//  VicCurio
//
//  Service for managing favourite items.
//

import Foundation
import SwiftData

@MainActor
final class FavouritesService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    func toggleFavourite(for item: CuriosityItem) {
        let id = item.id
        let descriptor = FetchDescriptor<PersistedItem>(
            predicate: #Predicate { $0.itemId == id }
        )

        if let persisted = try? modelContext.fetch(descriptor).first {
            // Toggle existing item
            persisted.isFavourite.toggle()
            persisted.favouritedAt = persisted.isFavourite ? Date() : nil
        } else {
            // Item not persisted yet, create it as favourite
            let newItem = PersistedItem(from: item)
            newItem.isFavourite = true
            newItem.favouritedAt = Date()
            modelContext.insert(newItem)
        }

        try? modelContext.save()
    }

    func isFavourite(_ item: CuriosityItem) -> Bool {
        let id = item.id
        let descriptor = FetchDescriptor<PersistedItem>(
            predicate: #Predicate { $0.itemId == id && $0.isFavourite == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    func isFavourite(itemId: String) -> Bool {
        let descriptor = FetchDescriptor<PersistedItem>(
            predicate: #Predicate { $0.itemId == itemId && $0.isFavourite == true }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    func fetchFavourites() -> [CuriosityItem] {
        let descriptor = FetchDescriptor<PersistedItem>(
            predicate: #Predicate { $0.isFavourite == true },
            sortBy: [SortDescriptor(\.favouritedAt, order: .reverse)]
        )

        guard let persisted = try? modelContext.fetch(descriptor) else {
            return []
        }

        return persisted.map { $0.toCuriosityItem() }
    }

    func markAsViewed(_ item: CuriosityItem) {
        let id = item.id
        let descriptor = FetchDescriptor<PersistedItem>(
            predicate: #Predicate { $0.itemId == id }
        )

        if let persisted = try? modelContext.fetch(descriptor).first {
            persisted.viewedAt = Date()
        } else {
            let newItem = PersistedItem(from: item)
            newItem.viewedAt = Date()
            modelContext.insert(newItem)
        }

        try? modelContext.save()
    }
}
