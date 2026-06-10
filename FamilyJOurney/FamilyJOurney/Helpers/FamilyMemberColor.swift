//
//  FamilyMemberColor.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import SwiftUI

// FamilyMemberColor keeps marker and route color choices in one reusable place.
enum FamilyMemberColor {
    // The palette gives each member a visually distinct marker and route color.
    private static let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]

    // This helper assigns stable colors from member names without storing Color in SwiftData.
    static func color(for memberName: String) -> Color {
        let index = abs(memberName.hashValue) % palette.count
        return palette[index]
    }
}
