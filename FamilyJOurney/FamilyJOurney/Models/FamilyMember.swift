//
//  FamilyMember.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import Foundation
import SwiftData
import SwiftUI

// FamilyMember represents a person in the family and contains their location journey stops.
@Model
final class FamilyMember {
    // Unique identifier for CloudKit compatibility and SwiftData tracking.
    var id: UUID = UUID()
    var name: String = ""
    var colorName: String = "blue"
    var emoji: String = "👤"
    
    // Binary image data of custom profile photos or Memojis.
    @Attribute(.externalStorage)
    var avatarImageData: Data? = nil
    
    // If a member is deleted, all their location records are cascade-deleted as well.
    @Relationship(deleteRule: .cascade, inverse: \LocationRecord.member)
    var locations: [LocationRecord]? = []

    init(id: UUID = UUID(), name: String = "", colorName: String = "blue", emoji: String = "👤", avatarImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.emoji = emoji
        self.avatarImageData = avatarImageData
        self.locations = []
    }
}

extension FamilyMember {
    // Maps the stored colorName string to a SwiftUI Color.
    var color: Color {
        Color.forName(colorName)
    }
}
