//
//  VicCurioWidget.swift
//  VicCurioWidget
//
//  Home Screen widget displaying today's museum artifact.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let item: WidgetItem?
    let imageData: Data?
    let errorMessage: String?

    static let placeholder = WidgetEntry(
        date: Date(),
        item: WidgetItem(
            id: "placeholder",
            title: "Loading...",
            summary: "Discovering today's curiosity",
            isMineralMonday: false
        ),
        imageData: nil,
        errorMessage: nil
    )
}

// MARK: - Widget Item (Simplified model for widget)

struct WidgetItem: Codable {
    let id: String
    let title: String
    let summary: String
    let isMineralMonday: Bool

    var deepLinkURL: URL {
        URL(string: "viccurio://item/\(id)")!
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    private let feedURL = URL(string: "https://davidcaddy.github.io/VicCurio/approved.json")!
    private let appGroupID = "group.armchairengineering.viccurio"

    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        // For preview, try to load cached data or use placeholder
        if let cached = loadCachedEntry() {
            completion(cached)
        } else {
            completion(.placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task {
            let entry = await fetchTodaysEntry()

            // Schedule next update at midnight or in 1 hour (whichever is sooner)
            let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
            let oneHour = Date().addingTimeInterval(3600)
            let nextUpdate = min(midnight, oneHour)

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    // MARK: - Private Methods

    private func fetchTodaysEntry() async -> WidgetEntry {
        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let feed = try JSONDecoder().decode(WidgetFeed.self, from: data)

            // Find today's item
            let today = formatDate(Date())
            guard let item = feed.items.first(where: { $0.displayDate == today }) else {
                return WidgetEntry(
                    date: Date(),
                    item: nil,
                    imageData: nil,
                    errorMessage: "No item scheduled for today"
                )
            }

            let widgetItem = WidgetItem(
                id: item.id,
                title: item.title,
                summary: item.summary,
                isMineralMonday: item.mineralMonday ?? false
            )

            // Fetch thumbnail image
            var imageData: Data? = nil
            if let thumbnailURL = URL(string: item.thumbnailUrl) {
                imageData = try? await URLSession.shared.data(from: thumbnailURL).0
            }

            let entry = WidgetEntry(
                date: Date(),
                item: widgetItem,
                imageData: imageData,
                errorMessage: nil
            )

            // Cache for offline use
            cacheEntry(entry)

            return entry
        } catch {
            // Try to use cached data on failure
            if let cached = loadCachedEntry() {
                return cached
            }

            return WidgetEntry(
                date: Date(),
                item: nil,
                imageData: nil,
                errorMessage: "Unable to load"
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func cacheEntry(_ entry: WidgetEntry) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let item = entry.item else { return }

        defaults.set(try? JSONEncoder().encode(item), forKey: "cachedWidgetItem")
        if let imageData = entry.imageData {
            defaults.set(imageData, forKey: "cachedWidgetImage")
        }
        defaults.set(Date(), forKey: "cachedWidgetDate")
    }

    private func loadCachedEntry() -> WidgetEntry? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let itemData = defaults.data(forKey: "cachedWidgetItem"),
              let item = try? JSONDecoder().decode(WidgetItem.self, from: itemData) else {
            return nil
        }

        let imageData = defaults.data(forKey: "cachedWidgetImage")

        return WidgetEntry(
            date: Date(),
            item: item,
            imageData: imageData,
            errorMessage: nil
        )
    }
}

// MARK: - Feed Models (Simplified for widget)

private struct WidgetFeed: Codable {
    let items: [WidgetFeedItem]
}

private struct WidgetFeedItem: Codable {
    let id: String
    let displayDate: String
    let title: String
    let summary: String
    let thumbnailUrl: String
    let mineralMonday: Bool?
}

// MARK: - Widget Views

struct VicCurioWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Title
            if let item = entry.item {
                VStack(alignment: .leading, spacing: 2) {
                    if item.isMineralMonday {
                        Label("Mineral Monday", systemImage: "diamond.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.green)
                    }

                    Text(item.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(12)
            } else if let error = entry.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(12)
            }
        }
        .widgetURL(entry.item?.deepLinkURL)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120)
            }

            // Content
            if let item = entry.item {
                VStack(alignment: .leading, spacing: 6) {
                    if item.isMineralMonday {
                        Label("Mineral Monday", systemImage: "diamond.fill")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }

                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.trailing, 12)
            } else if let error = entry.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Spacer(minLength: 0)
        }
        .widgetURL(entry.item?.deepLinkURL)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Large image
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minHeight: 180)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(minHeight: 180)
            }

            // Content
            if let item = entry.item {
                VStack(alignment: .leading, spacing: 8) {
                    if item.isMineralMonday {
                        HStack {
                            Label("Mineral Monday", systemImage: "diamond.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            
                            Spacer()
                        }
                    }

                    Text(item.title)
                        .font(.headline)
                        .lineLimit(3)

                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .layoutPriority(1)
            } else if let error = entry.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()

                Spacer()
            }
        }
        .widgetURL(entry.item?.deepLinkURL)
    }
}

// MARK: - Widget Configuration

struct VicCurioWidget: Widget {
    let kind: String = "VicCurioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VicCurioWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("VicCurio")
        .description("Today's curiosity from Museums Victoria")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    VicCurioWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        item: WidgetItem(
            id: "preview",
            title: "Gold Specimen from Ballarat",
            summary: "A stunning nugget discovered in 1858",
            isMineralMonday: true
        ),
        imageData: nil,
        errorMessage: nil
    )
}

#Preview("Medium", as: .systemMedium) {
    VicCurioWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        item: WidgetItem(
            id: "preview",
            title: "Gold Specimen from Ballarat",
            summary: "This remarkable gold nugget was discovered during the Victorian gold rush, showcasing the incredible mineral wealth of the region.",
            isMineralMonday: true
        ),
        imageData: nil,
        errorMessage: nil
    )
}

#Preview("Large", as: .systemLarge) {
    VicCurioWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        item: WidgetItem(
            id: "preview",
            title: "Gold Specimen from Ballarat",
            summary: "This remarkable gold nugget was discovered during the Victorian gold rush, showcasing the incredible mineral wealth of the region. Found by prospectors in the Ballarat goldfields.",
            isMineralMonday: true
        ),
        imageData: nil,
        errorMessage: nil
    )
}
