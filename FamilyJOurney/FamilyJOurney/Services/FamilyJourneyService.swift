//
//  FamilyJourneyService.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import Foundation
import SwiftData

// FamilyJourneyService acts as the single source of database operations (CRUD) for the application.
struct FamilyJourneyService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Family Member Operations

    /// Creates and inserts a new FamilyMember.
    func createFamilyMember(name: String) -> FamilyMember {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let colorNames = ["blue", "green", "orange", "purple", "pink", "red", "cyan", "indigo"]
        let colorIndex = abs(cleanName.hashValue) % colorNames.count
        let assignedColor = colorNames[colorIndex]

        let emojis = ["👩", "👨", "👧", "👦", "👵", "👴", "👩‍🦰", "👨‍🦱", "👱‍♀️", "👱‍♂️", "👶", "👩‍🦳", "👨‍🦳"]
        let emojiIndex = abs(cleanName.hashValue) % emojis.count
        let assignedEmoji = emojis[emojiIndex]

        let member = FamilyMember(name: cleanName, colorName: assignedColor, emoji: assignedEmoji)
        modelContext.insert(member)
        try? modelContext.save()
        return member
    }

    // MARK: - Location Record Operations

    /// Inserts a new location record and associates it with a family member.
    func insertLocation(
        cityName: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        note: String,
        member: FamilyMember
    ) {
        let record = LocationRecord(
            cityName: cityName.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        record.member = member
        modelContext.insert(record)
        
        if member.locations == nil {
            member.locations = []
        }
        member.locations?.append(record)
        
        try? modelContext.save()
    }

    /// Updates an existing location record and manages family member relationship changes.
    func updateLocation(
        record: LocationRecord,
        cityName: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        note: String,
        newMember: FamilyMember
    ) {
        record.cityName = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        record.latitude = latitude
        record.longitude = longitude
        record.timestamp = timestamp
        record.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle relationship updates if the member changed
        if record.member?.id != newMember.id {
            if let oldMember = record.member {
                oldMember.locations?.removeAll(where: { $0.id == record.id })
            }
            record.member = newMember
            if newMember.locations == nil {
                newMember.locations = []
            }
            newMember.locations?.append(record)
        }

        try? modelContext.save()
    }

    /// Deletes a location record from the database.
    func deleteLocation(record: LocationRecord) {
        if let member = record.member {
            member.locations?.removeAll(where: { $0.id == record.id })
        }
        modelContext.delete(record)
        try? modelContext.save()
    }
}
