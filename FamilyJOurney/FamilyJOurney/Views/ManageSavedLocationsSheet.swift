//
//  ManageSavedLocationsSheet.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct ManageSavedLocationsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SavedLocation.name) private var savedLocations: [SavedLocation]

    // Form inputs for adding a location
    @State private var name = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""

    // Map selection camera position centered on default Indonesia location
    @State private var mapCameraPosition: MapCameraPosition

    var initialCoordinate: CLLocationCoordinate2D?

    init(initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.initialCoordinate = initialCoordinate
        
        if let coordinate = initialCoordinate {
            _latitudeString = State(initialValue: String(format: "%.6f", coordinate.latitude))
            _longitudeString = State(initialValue: String(format: "%.6f", coordinate.longitude))
            _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )))
        } else {
            _latitudeString = State(initialValue: "")
            _longitudeString = State(initialValue: "")
            _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
                span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
            )))
        }
    }

    private var latitude: Double? {
        Double(latitudeString)
    }

    private var longitude: Double? {
        Double(longitudeString)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude != nil &&
        longitude != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add New Preset Location") {
                    TextField("Location Name (e.g. Home, Bali)", text: $name)
                        .autocorrectionDisabled()
                        .font(.body)
                    
                    TextField("Latitude (e.g. -6.2088)", text: $latitudeString)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .font(.body)
                        .onChange(of: latitudeString) { _, _ in
                            updateMapCamera()
                        }
                    
                    TextField("Longitude (e.g. 106.8456)", text: $longitudeString)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .font(.body)
                        .onChange(of: longitudeString) { _, _ in
                            updateMapCamera()
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or tap on the map to select coordinates:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        MapReader { proxy in
                            Map(position: $mapCameraPosition) {
                                if let lat = latitude, let lon = longitude {
                                    Marker(name.isEmpty ? "Selected" : name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                }
                            }
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.4), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                            .onTapGesture { position in
                                if let coordinate = proxy.convert(position, from: .local) {
                                    latitudeString = String(format: "%.6f", coordinate.latitude)
                                    longitudeString = String(format: "%.6f", coordinate.longitude)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    Button(action: savePresetLocation) {
                        HStack {
                            Spacer()
                            Text("Save Preset Location")
                                .font(.body)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.borderedProminent)
                }

                Section("Saved Locations (\(savedLocations.count))") {
                    if savedLocations.isEmpty {
                        Text("No saved locations yet. Create one above.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(savedLocations) { location in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(location.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Text(String(format: "Lat: %.4f, Lon: %.4f", location.latitude, location.longitude))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteLocation(location)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Saved Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.body)
                }
            }
            .onAppear {
                if let coordinate = initialCoordinate {
                    geocodeCoordinate(coordinate)
                }
            }
        }
    }

    private func updateMapCamera() {
        guard let lat = latitude, let lon = longitude else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))
    }

    private func savePresetLocation() {
        guard let lat = latitude, let lon = longitude else { return }
        
        let newLocation = SavedLocation(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: lat,
            longitude: lon
        )
        
        modelContext.insert(newLocation)
        try? modelContext.save()
        
        // Reset form inputs
        name = ""
        latitudeString = ""
        longitudeString = ""
    }

    private func deleteLocation(_ location: SavedLocation) {
        modelContext.delete(location)
        try? modelContext.save()
    }

    private func geocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            
            var addressParts: [String] = []
            if let name = placemark.name {
                addressParts.append(name)
            }
            if let locality = placemark.locality, placemark.name != locality {
                addressParts.append(locality)
            }
            if let adminArea = placemark.administrativeArea, placemark.locality != adminArea {
                addressParts.append(adminArea)
            }
            
            let resolvedCityName = addressParts.joined(separator: ", ")
            if !resolvedCityName.isEmpty {
                self.name = resolvedCityName
            }
        }
    }
}

#Preview {
    ManageSavedLocationsSheet()
        .modelContainer(for: [SavedLocation.self], inMemory: true)
}
