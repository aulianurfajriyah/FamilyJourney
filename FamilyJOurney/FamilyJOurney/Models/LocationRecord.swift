//
//  LocationRecord.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import Foundation
import SwiftData

// This SwiftData model is the single source of truth for one saved family location.
@Model
final class LocationRecord {
    // A stable identifier lets SwiftUI, MapKit selection, and SwiftData refer to the same record.
    var id: UUID = UUID()

    // The relationship linking this location record to its family member owner.
    var member: FamilyMember?

    // The relationship linking this location record to its predefined saved location.
    var savedLocation: SavedLocation?

    // The city name is shown in marker detail UI.
    var cityName: String = ""

    // Latitude is stored as a Double because SwiftData persists simple value types cleanly.
    var latitude: Double = 0.0

    // Longitude is stored separately from latitude instead of storing CLLocationCoordinate2D directly.
    var longitude: Double = 0.0

    // The timestamp defines the order of each member's journey history.
    var timestamp: Date = Date()

    // Notes are optional user-facing detail for a saved location.
    var note: String = ""

    // This initializer creates complete records from form input, sample data, or future import flows.
    init(
        id: UUID = UUID(),
        cityName: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        timestamp: Date = Date(),
        note: String = "",
        savedLocation: SavedLocation? = nil
    ) {
        self.id = id
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.note = note
        self.savedLocation = savedLocation
    }
}
