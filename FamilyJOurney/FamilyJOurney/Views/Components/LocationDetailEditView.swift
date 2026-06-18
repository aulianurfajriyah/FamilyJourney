//
//  LocationDetailEditView.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import MapKit
import SwiftUI

struct LocationDetailEditView: View {
    @Binding var editedMemberID: UUID?
    @Binding var editedNewMemberName: String
    @Binding var inputSource: LocationDetailSheet.LocationInputSource
    @Binding var editedSavedLocationID: UUID?
    @Binding var cityName: String
    @Binding var latitudeString: String
    @Binding var longitudeString: String
    @Binding var editedTimestamp: Date
    @Binding var editedNote: String
    @Binding var isShowingManagePresets: Bool
    @Binding var mapCameraPosition: MapCameraPosition
    
    let members: [FamilyMember]
    let savedLocations: [SavedLocation]
    let isFormValid: Bool
    
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        Form {
            MemberSelectionSection(
                selectedMemberID: $editedMemberID,
                newMemberName: $editedNewMemberName,
                members: members
            )

            Section("Location Details") {
                Picker("Input Source", selection: $inputSource) {
                    ForEach(LocationDetailSheet.LocationInputSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                
                if inputSource == .preset {
                    PresetLocationSection(
                        selectedSavedLocationID: $editedSavedLocationID,
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
                DatePicker("Journey Timestamp", selection: $editedTimestamp, displayedComponents: [.date, .hourAndMinute])
                    .font(.body) // Dynamic Type compliance
            }

            Section("Notes (Optional)") {
                TextField("Add notes about this trip...", text: $editedNote, axis: .vertical)
                    .font(.body) // Dynamic Type compliance
            }
        }
        .sheet(isPresented: $isShowingManagePresets) {
            ManageSavedLocationsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .font(.body)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: onSave)
                    .disabled(!isFormValid)
                    .font(.body)
            }
        }
    }
}
