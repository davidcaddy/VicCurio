//
//  Constants.swift
//  VicCurio
//
//  App-wide constants and configuration.
//

import Foundation

enum Constants {
    /// The URL for the approved feed JSON on GitHub Pages.
    /// Update this with your actual GitHub Pages URL after deployment.
    static let feedURL = URL(string: "https://davidcaddy.github.io/VicCurio/approved.json")!

    /// App Group identifier for sharing data with the widget.
    /// Configure this in Xcode under Signing & Capabilities if using App Groups.
    static let appGroupIdentifier = "group.armchairengineering.viccurio"

    /// URL scheme for deep linking from widget.
    static let urlScheme = "viccurio"

    /// Cache validity duration in seconds (1 hour).
    static let cacheValiditySeconds: TimeInterval = 3600

    /// Number of days to show in history view.
    static let historyDays = 14
}
