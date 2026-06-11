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

    // The record is optional because a selection can disappear after SwiftData updates or deletes data.
    let record: LocationRecord?

    // Editing State
    @State private var isEditing = false
    @State private var editedMemberID: UUID?
    @State private var editedNewMemberName = ""
    @State private var editedCityName = ""
    @State private var editedLatitudeString = ""
    @State private var editedLongitudeString = ""
    @State private var editedTimestamp = Date()
    @State private var editedNote = ""

    // Map selection camera position centered on default location
    @State private var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    ))

    // Parsing inputs to Doubles
    private var editedLatitude: Double? {
        Double(editedLatitudeString)
    }

    private var editedLongitude: Double? {
        Double(editedLongitudeString)
    }

    // Checking if form input is valid
    private var isFormValid: Bool {
        let isMemberValid = editedMemberID != nil || !editedNewMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isMemberValid &&
               !editedCityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               editedLatitude != nil &&
               editedLongitude != nil
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
                TextField("City Name (e.g. Bandung)", text: $editedCityName)
                    .autocorrectionDisabled()
                    .font(.body) // Dynamic Type compliance

                TextField("Latitude (e.g. -6.9175)", text: $editedLatitudeString)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .font(.body) // Dynamic Type compliance
                    .onChange(of: editedLatitudeString) { _, _ in
                        updateMapCamera()
                    }

                TextField("Longitude (e.g. 107.6191)", text: $editedLongitudeString)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .font(.body) // Dynamic Type compliance
                    .onChange(of: editedLongitudeString) { _, _ in
                        updateMapCamera()
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Or tap on the map to choose coordinates:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    MapReader { proxy in
                        Map(position: $mapCameraPosition) {
                            if let lat = editedLatitude, let lon = editedLongitude {
                                Marker(editedCityName.isEmpty ? "Selected" : editedCityName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
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
                                editedLatitudeString = String(format: "%.6f", coordinate.latitude)
                                editedLongitudeString = String(format: "%.6f", coordinate.longitude)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
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
        editedCityName = record.cityName
        editedLatitudeString = String(format: "%.6f", record.latitude)
        editedLongitudeString = String(format: "%.6f", record.longitude)
        editedTimestamp = record.timestamp
        editedNote = record.note
        
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        ))
        
        isEditing = true
    }

    private func updateMapCamera() {
        guard let lat = editedLatitude, let lon = editedLongitude else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        ))
    }

    private var service: FamilyJourneyService {
        FamilyJourneyService(modelContext: modelContext)
    }

    private func saveChanges() {
        guard let record, let lat = editedLatitude, let lon = editedLongitude else { return }
        
        let targetMember: FamilyMember
        if let editedMemberID {
            guard let existing = members.first(where: { $0.id == editedMemberID }) else { return }
            targetMember = existing
        } else {
            targetMember = service.createFamilyMember(name: editedNewMemberName)
        }
        
        service.updateLocation(
            record: record,
            cityName: editedCityName,
            latitude: lat,
            longitude: lon,
            timestamp: editedTimestamp,
            note: editedNote,
            newMember: targetMember
        )
        
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
