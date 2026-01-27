//
//  LocationData.swift
//  VicCurio
//
//  Location information for museum artifacts.
//

import Foundation
import CoreLocation

struct LocationData: Codable, Equatable {
    let name: String
    let region: String?
    let latitude: Double?
    let longitude: Double?
    let showOnMap: Bool

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var displayName: String {
        if let region = region {
            return "\(name), \(region)"
        }
        return name
    }
}
