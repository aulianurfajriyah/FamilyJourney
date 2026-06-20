//
//  LongPressAlertOverlay.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import CoreLocation
import SwiftUI

// MARK: - LongPressAlertOverlay
struct LongPressAlertOverlay: View {
    let coordinate: CLLocationCoordinate2D
    var onDismiss: () -> Void
    var onAddStop: (CLLocationCoordinate2D) -> Void
    var onSavePreset: (CLLocationCoordinate2D) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
                .transition(.opacity)

            // Glass card
            VStack(spacing: 20) {
                // Title + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose Action")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text(String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Actions
                VStack(spacing: 10) {
                    actionButton(title: "Add Journey Stop", tint: .accentColor, filled: true) {
                        onAddStop(coordinate)
                    }
                    actionButton(title: "Save as Preset Location", tint: .secondary, filled: false) {
                        onSavePreset(coordinate)
                    }
                    actionButton(title: "Cancel", tint: .secondary, filled: false) {
                        onDismiss()
                    }
                }
            }
            .padding(14)
            .frame(width: 300)
            .glassEffect(in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        }
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        tint: Color,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: filled ? .semibold : .medium))
                .foregroundStyle(filled ? .white : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(filled ? tint : Color.clear)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(filled ? Color.clear : tint.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
