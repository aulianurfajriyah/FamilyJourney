//
//  MemberFormViews.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import PhotosUI
import SwiftData
import SwiftUI

// MARK: - Add Member Sheet
struct AddMemberSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColorName = "blue"
    @State private var selectedEmoji = "👩"
    @State private var customEmojiInput = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarData: Data? = nil

    private var memberService: FamilyMemberService {
        FamilyMemberService(modelContext: modelContext)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Info") {
                    TextField("Name (e.g. Alice)", text: $name)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                }

                AvatarPhotoSection(
                    avatarData: $avatarData,
                    selectedItem: $selectedItem,
                    selectedEmoji: selectedEmoji,
                    selectedColorName: selectedColorName
                )

                AvatarEmojiSection(
                    selectedEmoji: $selectedEmoji,
                    customEmojiInput: $customEmojiInput
                )

                RouteColorSection(
                    selectedColorName: $selectedColorName
                )
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = memberService.createMember(name: name, colorName: selectedColorName, emoji: selectedEmoji, avatarImageData: avatarData)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .font(.body)
                }
            }
        }
    }
}

// MARK: - Edit Member Sheet
struct EditMemberSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let member: FamilyMember

    @State private var name: String
    @State private var selectedColorName: String
    @State private var selectedEmoji: String
    @State private var customEmojiInput = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarData: Data? = nil

    private var memberService: FamilyMemberService {
        FamilyMemberService(modelContext: modelContext)
    }

    init(member: FamilyMember) {
        self.member = member
        _name = State(initialValue: member.name)
        _selectedColorName = State(initialValue: member.colorName)
        _selectedEmoji = State(initialValue: member.emoji)
        _avatarData = State(initialValue: member.avatarImageData)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Info") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                }

                AvatarPhotoSection(
                    avatarData: $avatarData,
                    selectedItem: $selectedItem,
                    selectedEmoji: selectedEmoji,
                    selectedColorName: selectedColorName
                )

                AvatarEmojiSection(
                    selectedEmoji: $selectedEmoji,
                    customEmojiInput: $customEmojiInput
                )

                RouteColorSection(
                    selectedColorName: $selectedColorName
                )
            }
            .navigationTitle("Edit Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        memberService.updateMember(member: member, name: name, colorName: selectedColorName, emoji: selectedEmoji, avatarImageData: avatarData)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .font(.body)
                }
            }
        }
    }
}
