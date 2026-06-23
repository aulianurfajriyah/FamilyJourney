//
//  MemberSearchItemView.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import SwiftUI

struct MemberSearchItemView: View {
    let member: FamilyMember
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                MemberAvatarView(member: member, size: 54, borderWidth: 2)
                
                VStack(spacing: 2) {
                    Text(member.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    let count = member.locations?.count ?? 0
                    Text("\(count) \(count == 1 ? "stop" : "stops")")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}
