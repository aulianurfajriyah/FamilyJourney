//
//  PlaceItemView.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import SwiftUI

struct PlaceItemView: View {
    let name: String
    let icon: String
    let isAdded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isAdded ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isAdded ? .white : .accentColor)
                }
                
                VStack(spacing: 2) {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(isAdded ? "Fly" : "Add")
                        .font(.system(size: 10))
                        .foregroundColor(isAdded ? .secondary : .accentColor)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}
