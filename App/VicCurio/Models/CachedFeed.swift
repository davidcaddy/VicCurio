//
//  CachedFeed.swift
//  VicCurio
//
//  SwiftData model for caching the feed locally.
//

import Foundation
import SwiftData

@Model
final class CachedFeed {
    var version: String
    var generatedAt: String
    var fetchedAt: Date
    var itemsData: Data  // JSON-encoded items array

    init(from feed: ApprovedFeed) {
        self.version = feed.version
        self.generatedAt = feed.generatedAt
        self.fetchedAt = Date()
        self.itemsData = (try? JSONEncoder().encode(feed.items)) ?? Data()
    }

    func toApprovedFeed() -> ApprovedFeed {
        let items = (try? JSONDecoder().decode([CuriosityItem].self, from: itemsData)) ?? []
        return ApprovedFeed(version: version, generatedAt: generatedAt, items: items)
    }

    /// Check if cache is still valid (within 1 hour)
    var isValid: Bool {
        Date().timeIntervalSince(fetchedAt) < 3600
    }
}
