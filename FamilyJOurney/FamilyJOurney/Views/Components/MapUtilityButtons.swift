//
//  MapUtilityButtons.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import MapKit
import SwiftUI

/// The top-trailing button cluster shown over the map.
/// Contains the track-record toggle, the timelapse toggle, and the compass.
struct MapUtilityButtons: View {
    @Binding var isTrackRecordActive: Bool
    @Binding var isTimelapseActive: Bool

    let mapScope: Namespace.ID

    var body: some View {
        VStack(spacing: 12) {
            // Track record toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTrackRecordActive.toggle()
                }
            } label: {
                Image(systemName: isTrackRecordActive
                      ? "point.topleft.down.to.point.bottomright.curvepath.fill"
                      : "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isTrackRecordActive ? .accentColor : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isTrackRecordActive ? Color.accentColor.opacity(0.25) : Color.clear)
                    )
                    .glassEffect()
            }
            .buttonStyle(.plain)

            // Timelapse toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTimelapseActive.toggle()
                }
            } label: {
                Image(systemName: isTimelapseActive ? "clock.fill" : "clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isTimelapseActive ? .accentColor : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isTimelapseActive ? Color.accentColor.opacity(0.25) : Color.clear)
                    )
                    .glassEffect()
            }
            .buttonStyle(.plain)

            // Compass
            MapCompass(scope: mapScope)
                .mapControlVisibility(.automatic)
        }
        .padding(.trailing, 16)
        .padding(.top, 12)
    }
}
