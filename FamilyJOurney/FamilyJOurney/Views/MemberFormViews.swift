//
//  MemberFormViews.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import PhotosUI
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif

// MARK: - Color Palette Mapping Helper
func colorForName(_ name: String) -> Color {
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

    private let colors = ["blue", "green", "orange", "purple", "pink", "red", "cyan", "indigo"]
    private let popularEmojis = ["👩", "👨", "👧", "👦", "👵", "👴", "👩‍🦰", "👨‍🦱", "👱‍♀️", "👱‍♂️", "👶", "🐱", "🐶", "🦊", "🦁"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Info") {
                    TextField("Name (e.g. Alice)", text: $name)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                }

                Section("Avatar Photo (Memoji or Real Photo)") {
                    HStack(spacing: 16) {
                        if let avatarData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                        } else {
                            Text(selectedEmoji)
                                .font(.system(size: 40))
                                .frame(width: 70, height: 70)
                                .background(Circle().fill(Color.secondary.opacity(0.1)))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Label(avatarData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            
                            if avatarData != nil {
                                Button(role: .destructive) {
                                    avatarData = nil
                                    selectedItem = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                if let image = UIImage(data: data) {
                                    let resizedImage = image.resized(to: CGSize(width: 256, height: 256))
                                    if let compressedData = resizedImage?.pngData() ?? resizedImage?.jpegData(compressionQuality: 0.8) {
                                        avatarData = compressedData
                                    } else {
                                        avatarData = data
                                    }
                                } else {
                                    avatarData = data
                                }
                            }
                        }
                    }
                }

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

                Section("Route Color") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { colorName in
                            Circle()
                                .fill(colorForName(colorName))
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

    private let colors = ["blue", "green", "orange", "purple", "pink", "red", "cyan", "indigo"]
    private let popularEmojis = ["👩", "👨", "👧", "👦", "👵", "👴", "👩‍🦰", "👨‍🦱", "👱‍♀️", "👱‍♂️", "👶", "🐱", "🐶", "🦊", "🦁"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Info") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                }

                Section("Avatar Photo (Memoji or Real Photo)") {
                    HStack(spacing: 16) {
                        if let avatarData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                        } else {
                            Text(selectedEmoji)
                                .font(.system(size: 40))
                                .frame(width: 70, height: 70)
                                .background(Circle().fill(Color.secondary.opacity(0.1)))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Label(avatarData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            
                            if avatarData != nil {
                                Button(role: .destructive) {
                                    avatarData = nil
                                    selectedItem = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                if let image = UIImage(data: data) {
                                    let resizedImage = image.resized(to: CGSize(width: 256, height: 256))
                                    if let compressedData = resizedImage?.pngData() ?? resizedImage?.jpegData(compressionQuality: 0.8) {
                                        avatarData = compressedData
                                    } else {
                                        avatarData = data
                                    }
                                } else {
                                    avatarData = data
                                }
                            }
                        }
                    }
                }

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
                            if let lastChar = newValue.last {
                                selectedEmoji = String(lastChar)
                                customEmojiInput = String(lastChar)
                            }
                        }
                }

                Section("Route Color") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { colorName in
                            Circle()
                                .fill(colorForName(colorName))
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
