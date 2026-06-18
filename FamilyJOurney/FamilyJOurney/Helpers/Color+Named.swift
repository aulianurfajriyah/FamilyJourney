//
//  Color+Named.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

import SwiftUI

extension Color {
    static func forName(_ name: String) -> Color {
        switch name.lowercased() {
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
