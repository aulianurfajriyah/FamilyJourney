//
//  LocationDetailSheet.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import MapKit
import SwiftData
import SwiftUI

// LocationDetailSheet presents details for the selected marker and allows editing its values.
struct LocationDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @Query(sort: \SavedLocation.name) private var savedLocations: [SavedLocation]

    // The record is optional because a selection can disappear after SwiftData updates or deletes data.
    let record: LocationRecord?

    enum LocationInputSource: String, CaseIterable, Identifiable {
        case preset = "Saved Preset"
        case manual = "Manual Entry"
        var id: String { self.rawValue }
    }

    // Editing State
    @State private var isEditing = false
    @State private var editedMemberID: UUID?
    @State private var editedNewMemberName = ""
    @State private var inputSource: LocationInputSource = .preset
    @State private var editedSavedLocationID: UUID?
    @State private var cityName = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var editedTimestamp = Date()
    @State private var editedNote = ""
    @State private var isShowingManagePresets = false

    // Map selection camera position centered on default location
    @State private var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    ))

    private var selectedSavedLocation: SavedLocation? {
        savedLocations.first { $0.id == editedSavedLocationID }
    }

    private var manualLatitude: Double? {
        Double(latitudeString)
    }

    private var manualLongitude: Double? {
        Double(longitudeString)
    }

    // Checking if form input is valid
    private var isFormValid: Bool {
        let isMemberValid = editedMemberID != nil || !editedNewMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch inputSource {
        case .preset:
            return isMemberValid && editedSavedLocationID != nil
        case .manual:
            return isMemberValid &&
                   !cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   manualLatitude != nil &&
                   manualLongitude != nil
        }
    }

    // The body shows either selected record details, editing form, or a fallback message.
    var body: some View {
        NavigationStack {
            Group {
                if let record {
                    if isEditing {
                        editingForm(for: record)
                    } else {
                        readOnlyList(for: record)
                    }
                } else {
                    ContentUnavailableView("No Location Selected", systemImage: "mappin.slash")
                }
            }
            .navigationTitle(isEditing ? "Edit Location" : "Location Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Read-Only mode display list
    @ViewBuilder
    private func readOnlyList(for record: LocationRecord) -> some View {
        List {
            // This section explains who owns the location record.
            Section("Family Member") {
                Text(record.member?.name ?? "Unknown")
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows the place saved in SwiftData.
            Section("Location") {
                Text(record.cityName)
                    .font(.body) // Dynamic Type compliance
                Text("Latitude: \(record.latitude.formatted())")
                    .font(.body) // Dynamic Type compliance
                Text("Longitude: \(record.longitude.formatted())")
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows when the journey snapshot happened.
            Section("Time") {
                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows the optional note for the marker.
            if !record.note.isEmpty {
                Section("Note") {
                    Text(record.note)
                        .font(.body) // Dynamic Type compliance
                }
            }

            // Destructive section to delete this location stop from the database.
            Section {
                Button(role: .destructive) {
                    deleteRecord()
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Location Stop")
                            .font(.body) // Dynamic Type compliance
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden) // Liquid glass styling compliance
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    startEditing()
                }
                .font(.body)
            }
        }
    }

    // Editable form view layout
    @ViewBuilder
    private func editingForm(for record: LocationRecord) -> some View {
        Form {
            Section("Family Member") {
                Picker("Select Member", selection: $editedMemberID) {
                    Text("Add New Member...").tag(nil as UUID?)
                    ForEach(members) { member in
                        Text(member.name).tag(member.id as UUID?)
                    }
                }
                .font(.body) // Dynamic Type compliance
                
                if editedMemberID == nil {
                    TextField("New Member Name", text: $editedNewMemberName)
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
                            Picker("Select Place", selection: $editedSavedLocationID) {
                                Text("Choose location...").tag(nil as UUID?)
                                ForEach(savedLocations) { location in
                                    Text(location.name).tag(location.id as UUID?)
                                }
                            }
                            .font(.body)
                            .onChange(of: editedSavedLocationID) { _, _ in
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
                            .frame(height: 180)
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
                DatePicker("Journey Timestamp", selection: $editedTimestamp, displayedComponents: [.date, .hourAndMinute])
                    .font(.body) // Dynamic Type compliance
            }

            Section("Notes (Optional)") {
                TextField("Add notes about this trip...", text: $editedNote, axis: .vertical)
                    .font(.body) // Dynamic Type compliance
                    .lineLimit(3...5)
            }
        }
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
                    isEditing = false
                }
                .font(.body)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!isFormValid)
                .font(.body)
            }
        }
    }

    private func startEditing() {
        guard let record else { return }
        editedMemberID = record.member?.id
        editedNewMemberName = ""
        
        let foundPresetID = record.savedLocation?.id ?? savedLocations.first(where: {
            $0.latitude == record.latitude && $0.longitude == record.longitude
        })?.id
        
        if let foundPresetID {
            editedSavedLocationID = foundPresetID
            inputSource = .preset
            cityName = ""
            latitudeString = ""
            longitudeString = ""
        } else {
            editedSavedLocationID = nil
            inputSource = .manual
            cityName = record.cityName
            latitudeString = String(format: "%.6f", record.latitude)
            longitudeString = String(format: "%.6f", record.longitude)
        }
        
        editedTimestamp = record.timestamp
        editedNote = record.note
        
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
        
        isEditing = true
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

    private func saveChanges() {
        guard let record else { return }
        
        let targetMember: FamilyMember
        if let editedMemberID {
            guard let existing = members.first(where: { $0.id == editedMemberID }) else { return }
            targetMember = existing
        } else {
            targetMember = service.createFamilyMember(name: editedNewMemberName)
        }
        
        switch inputSource {
        case .preset:
            guard let location = selectedSavedLocation else { return }
            record.cityName = location.name
            record.latitude = location.latitude
            record.longitude = location.longitude
            record.savedLocation = location
        case .manual:
            guard let lat = manualLatitude, let lon = manualLongitude else { return }
            record.cityName = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
            record.latitude = lat
            record.longitude = lon
            record.savedLocation = nil
        }
        
        record.timestamp = editedTimestamp
        record.note = editedNote
        
        if record.member?.id != targetMember.id {
            if let oldMember = record.member {
                oldMember.locations?.removeAll(where: { $0.id == record.id })
            }
            record.member = targetMember
            if targetMember.locations == nil {
                targetMember.locations = []
            }
            targetMember.locations?.append(record)
        }
        
        try? modelContext.save()
        
        isEditing = false
    }

    private func deleteRecord() {
        guard let record else { return }
        service.deleteLocation(record: record)
        dismiss()
    }
}

#Preview {
    LocationDetailSheet(record: nil)
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
