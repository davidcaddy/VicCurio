//
//  CuriosityItem.swift
//  VicCurio
//
//  Model representing a museum artifact from the approved feed.
//

import Foundation

struct CuriosityItem: Codable, Identifiable, Hashable {
    let id: String
    let displayDate: String
    let title: String
    let summary: String
    let funFact: String?
    let imageUrl: URL
    let thumbnailUrl: URL
    let aspectRatio: Double?
    let credit: String
    let licence: String
    let museumUrl: URL
    let location: LocationData?
    let tags: [String]
    let mineralMonday: Bool

    // MARK: - Computed Properties

    var isMineralMonday: Bool {
        mineralMonday || tags.contains("mineral-monday")
    }

    var isLandscape: Bool {
        (aspectRatio ?? 1.0) > 1.0
    }

    var isPortrait: Bool {
        (aspectRatio ?? 1.0) < 1.0
    }

    var displayDateAsDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: displayDate)
    }

    var displayDateFormatted: String {
        guard let date = displayDateAsDate else { return displayDate }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    var isToday: Bool {
        guard let date = displayDateAsDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var attributionText: String {
        "\(credit) / \(licence)"
    }
}

// MARK: - Preview/Testing Support

extension CuriosityItem {
    static var preview: CuriosityItem {
        CuriosityItem(
            id: "items/123456",
            displayDate: Date().formatted(.iso8601.year().month().day()),
            title: "Pyrite Crystal from Ballarat",
            summary: "A stunning specimen of pyrite showing characteristic cubic crystal habit, collected from the Ballarat goldfields. Pyrite, also known as 'fool's gold', forms in a variety of geological environments.",
            funFact: "Pyrite's name comes from the Greek word 'pyr' meaning fire, because it produces sparks when struck against metal!",
            imageUrl: URL(string: "https://example.com/image.webp")!,
            thumbnailUrl: URL(string: "https://example.com/thumb.webp")!,
            aspectRatio: 1.333,
            credit: "Museums Victoria",
            licence: "CC BY",
            museumUrl: URL(string: "https://collections.museumsvictoria.com.au/items/123456")!,
            location: LocationData(
                name: "Ballarat",
                region: "Central Highlands",
                latitude: -37.5622,
                longitude: 143.8503,
                showOnMap: true,
                locality: nil,
                state: nil,
                country: nil
            ),
            tags: ["geology", "minerals", "mineral-monday"],
            mineralMonday: true
        )
    }
}
