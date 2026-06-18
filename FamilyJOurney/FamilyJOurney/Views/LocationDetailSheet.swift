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
                        LocationDetailEditView(
                            editedMemberID: $editedMemberID,
                            editedNewMemberName: $editedNewMemberName,
                            inputSource: $inputSource,
                            editedSavedLocationID: $editedSavedLocationID,
                            cityName: $cityName,
                            latitudeString: $latitudeString,
                            longitudeString: $longitudeString,
                            editedTimestamp: $editedTimestamp,
                            editedNote: $editedNote,
                            isShowingManagePresets: $isShowingManagePresets,
                            mapCameraPosition: $mapCameraPosition,
                            members: members,
                            savedLocations: savedLocations,
                            isFormValid: isFormValid,
                            onCancel: { isEditing = false },
                            onSave: { saveChanges() }
                        )
                    } else {
                        LocationDetailReadOnlyView(
                            record: record,
                            onEdit: { startEditing() },
                            onDelete: { deleteRecord() }
                        )
                    }
                } else {
                    ContentUnavailableView("No Location Selected", systemImage: "mappin.slash")
                }
            }
            .navigationTitle(isEditing ? "Edit Location" : "Location Details")
            .navigationBarTitleDisplayMode(.inline)
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
