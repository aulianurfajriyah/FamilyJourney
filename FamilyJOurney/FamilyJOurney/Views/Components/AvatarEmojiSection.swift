//
//  AvatarEmojiSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

import SwiftUI

struct AvatarEmojiSection: View {
    @Binding var selectedEmoji: String
    @Binding var customEmojiInput: String

    private let popularEmojis = ["👩", "👨", "👧", "👦", "👵", "👴", "👩‍🦰", "👨‍🦱", "👱‍♀️", "👱‍♂️", "👶", "🐱", "🐶", "🦊", "🦁"]

    var body: some View {
        Section("Avatar Emoji (Fallback)") {
            // Emoji Picker Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(popularEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 32))
                            .padding(8)
                            .background(Circle().fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear))
                            .onTapGesture {
                                selectedEmoji = emoji
                            }
                    }
                }
            }
            .padding(.vertical, 4)

            TextField("Type custom emoji (optional)", text: $customEmojiInput)
                .autocorrectionDisabled()
                .font(.body) // Dynamic Type compliance
                .onChange(of: customEmojiInput) { _, newValue in
                    // Restrict to last entered character to keep it a single emoji
                    if let lastChar = newValue.last {
                        selectedEmoji = String(lastChar)
                        customEmojiInput = String(lastChar)
                    }
                }
        }
    }
}
