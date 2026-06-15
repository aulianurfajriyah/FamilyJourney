//
//  SavedLocation.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import Foundation
import SwiftData

// SavedLocation represents a reusable preset coordinate location with a custom name.
@Model
final class SavedLocation {
    // Unique identifier for SwiftData and UI identity
    var id: UUID = UUID()
    
    // The user-assigned name of the location (e.g. "Home", "Office")
    var name: String = ""
    
    // The latitude coordinate
    var latitude: Double = 0.0
    
    // The longitude coordinate
    var longitude: Double = 0.0
    
    // Reverse relationship linking to location check-ins.
    // If the saved preset location is deleted, we nullify the connection on associated
    // check-ins, but keep their local coordinate/name copies intact.
    @Relationship(deleteRule: .nullify, inverse: \LocationRecord.savedLocation)
    var records: [LocationRecord]? = []
    
    init(id: UUID = UUID(), name: String = "", latitude: Double = 0.0, longitude: Double = 0.0) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.records = []
    }
}
