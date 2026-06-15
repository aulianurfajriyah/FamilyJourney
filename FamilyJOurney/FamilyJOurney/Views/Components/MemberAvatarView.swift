//
//  MemberAvatarView.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import SwiftUI
import SwiftData

// MemberAvatarView displays a family member profile image or fallback emoji avatar.
struct MemberAvatarView: View {
    let avatarImageData: Data?
    let emoji: String
    let color: Color
    var size: CGFloat = 38
    var showBorder: Bool = true
    var borderWidth: CGFloat = 2.5
    var borderColor: Color? = nil
    
    // Convenience initializer for FamilyMember model
    init(member: FamilyMember, size: CGFloat = 38, showBorder: Bool = true, borderWidth: CGFloat = 2.5, borderColor: Color? = nil) {
        self.avatarImageData = member.avatarImageData
        self.emoji = member.emoji
        self.color = member.color
        self.size = size
        self.showBorder = showBorder
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    // Initializer for raw properties (e.g. form inputs where model isn't created yet)
    init(avatarImageData: Data?, emoji: String, color: Color, size: CGFloat = 38, showBorder: Bool = true, borderWidth: CGFloat = 2.5, borderColor: Color? = nil) {
        self.avatarImageData = avatarImageData
        self.emoji = emoji
        self.color = color
        self.size = size
        self.showBorder = showBorder
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }

    var body: some View {
        Group {
            if let avatarImageData, let uiImage = UIImage(data: avatarImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(emoji)
                    .font(.system(size: size * 0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Circle().fill(color.opacity(0.15)))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(Circle().fill(Color(uiColor: .systemBackground)))
        .overlay(
            Group {
                if showBorder {
                    Circle()
                        .stroke(borderColor ?? color, lineWidth: borderWidth)
                }
            }
        )
    }
}

// MemberAvatarStackView displays an overlapping horizontal row of avatars with a remaining count bubble.
struct MemberAvatarStackView: View {
    let members: [FamilyMember]
    var avatarSize: CGFloat = 32
    var limit: Int = 3
    
    var body: some View {
        let displayedMembers = Array(members.prefix(limit))
        let remainingCount = members.count - displayedMembers.count
        
        HStack(spacing: -10) {
            ForEach(displayedMembers) { member in
                MemberAvatarView(member: member, size: avatarSize, borderWidth: 2)
            }
            
            if remainingCount > 0 {
                Text("+\(remainingCount)")
                    .font(.system(size: avatarSize * 0.35, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(Circle().fill(Color.gray))
                    .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(uiColor: .systemBackground)))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
