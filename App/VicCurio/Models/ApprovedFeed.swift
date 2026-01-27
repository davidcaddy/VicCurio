//
//  ApprovedFeed.swift
//  VicCurio
//
//  Container for the approved feed JSON structure.
//

import Foundation

struct ApprovedFeed: Codable {
    let version: String
    let generatedAt: String
    let items: [CuriosityItem]

    /// Find the item scheduled for a specific date.
    /// Falls back to most recent past item if no exact match.
    func itemForDate(_ date: Date) -> CuriosityItem? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        // First try exact match
        if let item = items.first(where: { $0.displayDate == dateString }) {
            return item
        }

        // Fallback to most recent past item
        let pastItems = items
            .filter { $0.displayDate <= dateString }
            .sorted { $0.displayDate > $1.displayDate }

        return pastItems.first
    }

    /// Get items for the past N days
    func recentItems(days: Int) -> [CuriosityItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return items.filter { item in
            guard let itemDate = item.displayDateAsDate else { return false }
            let daysDiff = calendar.dateComponents([.day], from: itemDate, to: today).day ?? 0
            return daysDiff >= 0 && daysDiff < days
        }.sorted { ($0.displayDateAsDate ?? .distantPast) > ($1.displayDateAsDate ?? .distantPast) }
    }
}

// MARK: - Preview Support

extension ApprovedFeed {
    static var preview: ApprovedFeed {
        ApprovedFeed(
            version: "3.0",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            items: [.preview]
        )
    }

    static var empty: ApprovedFeed {
        ApprovedFeed(
            version: "3.0",
            generatedAt: "",
            items: []
        )
    }
}
