//
//  FeedService.swift
//  VicCurio
//
//  Service for fetching and caching the approved feed.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class FeedService {
    static let shared = FeedService()

    private(set) var isLoading = false
    private(set) var error: FeedError?

    private init() {}

    // MARK: - Public Methods

    func fetchTodaysItem(modelContext: ModelContext) async throws -> CuriosityItem {
        let feed = try await fetchFeed(modelContext: modelContext)

        guard let item = feed.itemForDate(Date()) else {
            throw FeedError.noItemForToday
        }

        return item
    }

    func fetchItem(for date: Date, modelContext: ModelContext) async throws -> CuriosityItem? {
        let feed = try await fetchFeed(modelContext: modelContext)
        return feed.itemForDate(date)
    }

    func fetchRecentItems(days: Int = Constants.historyDays, modelContext: ModelContext) async throws -> [CuriosityItem] {
        let feed = try await fetchFeed(modelContext: modelContext)
        return feed.recentItems(days: days)
    }

    func fetchFeed(modelContext: ModelContext, forceRefresh: Bool = false) async throws -> ApprovedFeed {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Check cache first (unless forcing refresh)
        if !forceRefresh, let cached = loadCachedFeed(modelContext: modelContext), cached.isValid {
            return cached.toApprovedFeed()
        }

        // Fetch from network
        do {
            let feed = try await fetchFromNetwork()

            // Update cache
            saveFeedToCache(feed, modelContext: modelContext)

            // Persist items to SwiftData for history
            persistItems(feed.items, modelContext: modelContext)

            return feed
        } catch {
            // Fall back to cache if network fails
            if let cached = loadCachedFeed(modelContext: modelContext) {
                self.error = .networkErrorWithCache(error)
                return cached.toApprovedFeed()
            }
            self.error = .networkError(error)
            throw FeedError.networkError(error)
        }
    }

    // MARK: - Private Methods

    private func fetchFromNetwork() async throws -> ApprovedFeed {
        let (data, response) = try await URLSession.shared.data(from: Constants.feedURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FeedError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ApprovedFeed.self, from: data)
    }

    private func loadCachedFeed(modelContext: ModelContext) -> CachedFeed? {
        let descriptor = FetchDescriptor<CachedFeed>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func saveFeedToCache(_ feed: ApprovedFeed, modelContext: ModelContext) {
        // Remove old cache entries
        let descriptor = FetchDescriptor<CachedFeed>()
        if let oldCaches = try? modelContext.fetch(descriptor) {
            for cache in oldCaches {
                modelContext.delete(cache)
            }
        }

        // Save new cache
        let cached = CachedFeed(from: feed)
        modelContext.insert(cached)
        try? modelContext.save()
    }

    private func persistItems(_ items: [CuriosityItem], modelContext: ModelContext) {
        for item in items {
            let id = item.id
            let descriptor = FetchDescriptor<PersistedItem>(
                predicate: #Predicate { $0.itemId == id }
            )

            if let existing = try? modelContext.fetch(descriptor).first {
                existing.update(from: item)
            } else {
                let persisted = PersistedItem(from: item)
                modelContext.insert(persisted)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Error Types

    enum FeedError: LocalizedError {
        case networkError(Error)
        case networkErrorWithCache(Error)
        case invalidResponse
        case httpError(Int)
        case noItemForToday

        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Unable to fetch today's curiosity. Please check your connection."
            case .networkErrorWithCache:
                return "Using cached content. Check your connection for updates."
            case .invalidResponse:
                return "Received an invalid response from the server."
            case .httpError(let code):
                return "Server error (code \(code)). Please try again later."
            case .noItemForToday:
                return "No curiosity scheduled for today. Check back tomorrow!"
            }
        }
    }
}
