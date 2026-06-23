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
   
    var id: UUID = UUID()
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
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
