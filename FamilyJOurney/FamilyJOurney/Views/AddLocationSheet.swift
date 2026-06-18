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
                MemberSelectionSection(
                    selectedMemberID: $selectedMemberID,
                    newMemberName: $newMemberName,
                    members: members
                )

                Section("Location Details") {
                    Picker("Input Source", selection: $inputSource) {
                        ForEach(LocationInputSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if inputSource == .preset {
                        PresetLocationSection(
                            selectedSavedLocationID: $selectedSavedLocationID,
                            isShowingManagePresets: $isShowingManagePresets,
                            mapCameraPosition: $mapCameraPosition,
                            savedLocations: savedLocations
                        )
                    } else {
                        ManualLocationSection(
                            cityName: $cityName,
                            latitudeString: $latitudeString,
                            longitudeString: $longitudeString,
                            mapCameraPosition: $mapCameraPosition
                        )
                    }
                }

                Section("Timeline") {
                    DatePicker("Journey Timestamp", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                        .font(.body) // Dynamic Type compliance
                }

                Section("Notes (Optional)") {
                    TextField("Add notes about this trip...", text: $note, axis: .vertical)
                        .font(.body) // Dynamic Type compliance
                }
            }
            .navigationTitle("Add Journey Stop")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingManagePresets) {
                ManageSavedLocationsSheet()
                    .presentationDetents([.medium, .large])
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
