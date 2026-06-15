//
//  AddLocationSheet.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import MapKit
import SwiftData
import SwiftUI

struct AddLocationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]

    enum LocationInputSource: String, CaseIterable, Identifiable {
        case preset = "Saved Preset"
        case manual = "Manual Entry"
        var id: String { self.rawValue }
    }

    @Query(sort: \SavedLocation.name) private var savedLocations: [SavedLocation]

    // Form inputs
    @State private var selectedMemberID: UUID?
    @State private var newMemberName = ""
    @State private var inputSource: LocationInputSource = .preset
    @State private var selectedSavedLocationID: UUID?
    @State private var cityName = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var timestamp = Date()
    @State private var note = ""
    @State private var isShowingManagePresets = false

    // Map camera position centered on default Indonesia location
    @State private var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    ))

    private var selectedSavedLocation: SavedLocation? {
        savedLocations.first { $0.id == selectedSavedLocationID }
    }

    private var manualLatitude: Double? {
        Double(latitudeString)
    }

    private var manualLongitude: Double? {
        Double(longitudeString)
    }

    // Checking if form input is valid
    private var isFormValid: Bool {
        let isMemberValid = selectedMemberID != nil || !newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch inputSource {
        case .preset:
            return isMemberValid && selectedSavedLocationID != nil
        case .manual:
            return isMemberValid &&
                   !cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   manualLatitude != nil &&
                   manualLongitude != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Family Member") {
                    Picker("Select Member", selection: $selectedMemberID) {
                        Text("Add New Member...").tag(nil as UUID?)
                        ForEach(members) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                    .font(.body) // Dynamic Type compliance
                    
                    if selectedMemberID == nil {
                        TextField("New Member Name", text: $newMemberName)
                            .autocorrectionDisabled()
                            .font(.body) // Dynamic Type compliance
                    }
                }

                Section("Location Details") {
                    Picker("Input Source", selection: $inputSource) {
                        ForEach(LocationInputSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if inputSource == .preset {
                        if savedLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("No saved locations available.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { isShowingManagePresets = true }) {
                                    Label("Manage Preset Locations", systemImage: "mappin.circle.fill")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                                .buttonStyle(.borderedProminent)
                            }
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
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    } else {
                        TextField("City Name (e.g. Bandung)", text: $cityName)
                            .autocorrectionDisabled()
                            .font(.body)

                        TextField("Latitude (e.g. -6.9175)", text: $latitudeString)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .font(.body)
                            .onChange(of: latitudeString) { _, _ in
                                updateManualMapCamera()
                            }

                        TextField("Longitude (e.g. 107.6191)", text: $longitudeString)
                            .keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                            .font(.body)
                            .onChange(of: longitudeString) { _, _ in
                                updateManualMapCamera()
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or tap on the map to choose coordinates:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            MapReader { proxy in
                                Map(position: $mapCameraPosition) {
                                    if let lat = manualLatitude, let lon = manualLongitude {
                                        Marker(cityName.isEmpty ? "Selected" : cityName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                    }
                                }
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture { position in
                                    if let coordinate = proxy.convert(position, from: .local) {
                                        latitudeString = String(format: "%.6f", coordinate.latitude)
                                        longitudeString = String(format: "%.6f", coordinate.longitude)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Timeline") {
                    DatePicker("Journey Timestamp", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                        .font(.body) // Dynamic Type compliance
                }

                Section("Notes (Optional)") {
                    TextField("Add notes about this trip...", text: $note, axis: .vertical)
                        .font(.body) // Dynamic Type compliance
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Journey Stop")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden) // Liquid glass styling
            .sheet(isPresented: $isShowingManagePresets) {
                ManageSavedLocationsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(!isFormValid)
                    .font(.body)
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

    private func updateManualMapCamera() {
        guard let lat = manualLatitude, let lon = manualLongitude else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }

    private var service: FamilyJourneyService {
        FamilyJourneyService(modelContext: modelContext)
    }

    private func saveLocation() {
        let targetMember: FamilyMember
        if let selectedMemberID {
            guard let existing = members.first(where: { $0.id == selectedMemberID }) else { return }
            targetMember = existing
        } else {
            targetMember = service.createFamilyMember(name: newMemberName)
        }
        
        let record: LocationRecord
        switch inputSource {
        case .preset:
            guard let location = selectedSavedLocation else { return }
            record = LocationRecord(
                cityName: location.name,
                latitude: location.latitude,
                longitude: location.longitude,
                timestamp: timestamp,
                note: note,
                savedLocation: location
            )
        case .manual:
            guard let lat = manualLatitude, let lon = manualLongitude else { return }
            record = LocationRecord(
                cityName: cityName.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: lat,
                longitude: lon,
                timestamp: timestamp,
                note: note,
                savedLocation: nil
            )
        }
        
        record.member = targetMember
        modelContext.insert(record)
        
        if targetMember.locations == nil {
            targetMember.locations = []
        }
        targetMember.locations?.append(record)
        
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    AddLocationSheet()
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
