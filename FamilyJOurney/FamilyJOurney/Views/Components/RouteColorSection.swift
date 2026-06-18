//
//  RouteColorSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

import SwiftUI

struct RouteColorSection: View {
    @Binding var selectedColorName: String

    private let colors = ["blue", "green", "orange", "purple", "pink", "red", "cyan", "indigo"]

    var body: some View {
        Section("Route Color") {
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { colorName in
                    Circle()
                        .fill(Color.forName(colorName))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColorName == colorName ? 2.5 : 0)
                        )
                        .onTapGesture {
                            selectedColorName = colorName
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
