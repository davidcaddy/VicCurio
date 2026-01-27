//
//  LocationData.swift
//  VicCurio
//
//  Location information for museum artifacts.
//

import Foundation
import CoreLocation

struct LocationData: Codable, Equatable {
    // Primary fields (new format)
    let name: String?
    let region: String?
    let latitude: Double?
    let longitude: Double?
    let showOnMap: Bool?

    // Legacy fields (from Museums Victoria API)
    let locality: String?
    let state: String?
    let country: String?

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var displayName: String {
        // Use name if available, otherwise build from legacy fields
        if let name = name {
            if let region = region {
                return "\(name), \(region)"
            }
            return name
        }

        // Fallback to legacy format
        var parts: [String] = []
        if let locality = locality {
            parts.append(locality)
        }
        if let region = region {
            parts.append(region)
        } else if let state = state {
            parts.append(state)
        }
        return parts.isEmpty ? "Unknown" : parts.joined(separator: ", ")
    }

    var shouldShowOnMap: Bool {
        showOnMap ?? false
    }
}
