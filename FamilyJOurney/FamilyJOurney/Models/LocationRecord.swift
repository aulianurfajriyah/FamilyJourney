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
    var id: UUID = UUID()
    var member: FamilyMember?
    var savedLocation: SavedLocation?


    var cityName: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timestamp: Date = Date()
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
