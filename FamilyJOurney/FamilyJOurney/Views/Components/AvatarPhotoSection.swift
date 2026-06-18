//
//  AvatarPhotoSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

import PhotosUI
import SwiftUI

struct AvatarPhotoSection: View {
    @Binding var avatarData: Data?
    @Binding var selectedItem: PhotosPickerItem?
    let selectedEmoji: String
    let selectedColorName: String

    var body: some View {
        Section("Avatar Photo (Memoji or Real Photo)") {
            HStack(spacing: 16) {
                MemberAvatarView(
                    avatarImageData: avatarData,
                    emoji: selectedEmoji,
                    color: Color.forName(selectedColorName),
                    size: 70,
                    showBorder: false
                )
                
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
                        #if canImport(UIKit)
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
                        #else
                        avatarData = data
                        #endif
                    }
                }
            }
        }
    }
}
