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
    
    // The name of the family member, used to group their journeys.
    var name: String = ""
    
    // The name of the color used for rendering markers and polylines of this member.
    var colorName: String = "blue"
    
    // The emoji character representing this member's map avatar.
    var emoji: String = "👤"
    
    // Binary image data of custom profile photos or Memojis.
    @Attribute(.externalStorage)
    var avatarImageData: Data? = nil
    
    // CloudKit compatible relationship: must be optional.
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
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}
