//
//  FamilyMemberService.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import Foundation
import SwiftData

// FamilyMemberService handles CRUD database operations specifically for FamilyMember objects.
struct FamilyMemberService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Creates and inserts a new FamilyMember.
    func createMember(name: String, colorName: String, emoji: String, avatarImageData: Data?) -> FamilyMember {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let member = FamilyMember(
            name: cleanName,
            colorName: colorName.lowercased(),
            emoji: cleanEmoji.isEmpty ? "👤" : cleanEmoji,
            avatarImageData: avatarImageData
        )
        modelContext.insert(member)
        try? modelContext.save()
        return member
    }

    /// Updates an existing FamilyMember.
    func updateMember(member: FamilyMember, name: String, colorName: String, emoji: String, avatarImageData: Data?) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        member.name = cleanName
        member.colorName = colorName.lowercased()
        member.emoji = cleanEmoji.isEmpty ? "👤" : cleanEmoji
        member.avatarImageData = avatarImageData
        
        try? modelContext.save()
    }

    /// Deletes a FamilyMember and cascade deletes all locations associated with them.
    func deleteMember(member: FamilyMember) {
        modelContext.delete(member)
        try? modelContext.save()
    }
}
