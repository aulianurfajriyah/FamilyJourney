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
    var id: UUID

    // The family member name is intentionally simple for the MVP instead of a separate relationship model.
    var familyMemberName: String

    // The city name is shown in marker detail UI.
    var cityName: String

    // Latitude is stored as a Double because SwiftData persists simple value types cleanly.
    var latitude: Double

    // Longitude is stored separately from latitude instead of storing CLLocationCoordinate2D directly.
    var longitude: Double

    // The timestamp defines the order of each member's journey history.
    var timestamp: Date

    // Notes are optional user-facing detail for a saved location.
    var note: String

    // This initializer creates complete records from form input, sample data, or future import flows.
    init(
        id: UUID = UUID(),
        familyMemberName: String,
        cityName: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.familyMemberName = familyMemberName
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.note = note
    }
}
