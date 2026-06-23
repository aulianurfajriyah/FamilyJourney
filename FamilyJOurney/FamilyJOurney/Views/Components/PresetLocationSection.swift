//
//  PresetLocationSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import MapKit
import SwiftData
import SwiftUI

struct PresetLocationSection: View {
    @Binding var selectedSavedLocationID: UUID?
    @Binding var isShowingManagePresets: Bool
    @Binding var mapCameraPosition: MapCameraPosition
    let savedLocations: [SavedLocation]

    private var selectedSavedLocation: SavedLocation? {
        savedLocations.first { $0.id == selectedSavedLocationID }
    }

    var body: some View {
        Group {
            if savedLocations.isEmpty {
                VStack(spacing: 12) {
                    Text("No saved locations available.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { isShowingManagePresets = true }) {
                        Text("Manage Preset Locations")
                            .font(.body)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                
            } else {
                HStack {
                    Picker("Select Place", selection: $selectedSavedLocationID) {
                        Text("Choose location...").tag(nil as UUID?)
                        ForEach(savedLocations) { location in
                            Text(location.name).tag(location.id as UUID?)
                        }
                    }
                    .font(.body)
                    .onChange(of: selectedSavedLocationID) { _, _ in
                        updateMapCamera()
                    }
                    
                    Button(action: { isShowingManagePresets = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                }

                if let selectedLocation = selectedSavedLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coordinates: \(String(format: "%.4f, %.4f", selectedLocation.latitude, selectedLocation.longitude))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Map(position: $mapCameraPosition) {
                            Marker(selectedLocation.name, coordinate: CLLocationCoordinate2D(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude))
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func updateMapCamera() {
        guard let location = selectedSavedLocation else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
}
