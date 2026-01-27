//
//  PersistedItem.swift
//  VicCurio
//
//  SwiftData model for storing items locally (history and favourites).
//

import Foundation
import SwiftData

@Model
final class PersistedItem {
    @Attribute(.unique) var itemId: String
    var displayDate: String
    var title: String
    var summary: String
    var funFact: String?
    var imageUrlString: String
    var thumbnailUrlString: String
    var aspectRatio: Double?
    var credit: String
    var licence: String
    var museumUrlString: String

    // Location data (flattened for SwiftData)
    var locationName: String?
    var locationRegion: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationShowOnMap: Bool

    var tags: [String]
    var mineralMonday: Bool

    // User state
    var isFavourite: Bool = false
    var favouritedAt: Date?
    var viewedAt: Date?

    init(from item: CuriosityItem) {
        self.itemId = item.id
        self.displayDate = item.displayDate
        self.title = item.title
        self.summary = item.summary
        self.funFact = item.funFact
        self.imageUrlString = item.imageUrl.absoluteString
        self.thumbnailUrlString = item.thumbnailUrl.absoluteString
        self.aspectRatio = item.aspectRatio
        self.credit = item.credit
        self.licence = item.licence
        self.museumUrlString = item.museumUrl.absoluteString
        self.locationName = item.location?.name
        self.locationRegion = item.location?.region
        self.locationLatitude = item.location?.latitude
        self.locationLongitude = item.location?.longitude
        self.locationShowOnMap = item.location?.shouldShowOnMap ?? false
        self.tags = item.tags
        self.mineralMonday = item.mineralMonday
    }

    func update(from item: CuriosityItem) {
        self.title = item.title
        self.summary = item.summary
        self.funFact = item.funFact
        self.imageUrlString = item.imageUrl.absoluteString
        self.thumbnailUrlString = item.thumbnailUrl.absoluteString
        self.aspectRatio = item.aspectRatio
        self.credit = item.credit
        self.licence = item.licence
        // Preserve user state (isFavourite, favouritedAt, viewedAt)
    }

    func toCuriosityItem() -> CuriosityItem {
        let location: LocationData?
        if locationName != nil || locationRegion != nil {
            location = LocationData(
                name: locationName,
                region: locationRegion,
                latitude: locationLatitude,
                longitude: locationLongitude,
                showOnMap: locationShowOnMap,
                locality: nil,
                state: nil,
                country: nil
            )
        } else {
            location = nil
        }

        return CuriosityItem(
            id: itemId,
            displayDate: displayDate,
            title: title,
            summary: summary,
            funFact: funFact,
            imageUrl: URL(string: imageUrlString) ?? URL(string: "about:blank")!,
            thumbnailUrl: URL(string: thumbnailUrlString) ?? URL(string: "about:blank")!,
            aspectRatio: aspectRatio,
            credit: credit,
            licence: licence,
            museumUrl: URL(string: museumUrlString) ?? URL(string: "about:blank")!,
            location: location,
            tags: tags,
            mineralMonday: mineralMonday
        )
    }
}
