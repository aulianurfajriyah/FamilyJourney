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

    // Form inputs
    @State private var selectedMemberID: UUID?
    @State private var newMemberName = ""
    @State private var cityName = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var timestamp = Date()
    @State private var note = ""

    // Map selection camera position centered on default Indonesia location
    @State private var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    ))

    // Parsing inputs to Doubles
    private var latitude: Double? {
        Double(latitudeString)
    }

    private var longitude: Double? {
        Double(longitudeString)
    }

    // Checking if form input is valid
    private var isFormValid: Bool {
        let isMemberValid = selectedMemberID != nil || !newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isMemberValid &&
               !cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               latitude != nil &&
               longitude != nil
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
                    TextField("City Name (e.g. Bandung)", text: $cityName)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance

                    TextField("Latitude (e.g. -6.9175)", text: $latitudeString)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                        .onChange(of: latitudeString) { _, _ in
                            updateMapCamera()
                        }

                    TextField("Longitude (e.g. 107.6191)", text: $longitudeString)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .font(.body) // Dynamic Type compliance
                        .onChange(of: longitudeString) { _, _ in
                            updateMapCamera()
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or tap on the map to choose coordinates:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        MapReader { proxy in
                            Map(position: $mapCameraPosition) {
                                if let lat = latitude, let lon = longitude {
                                    Marker(cityName.isEmpty ? "Selected" : cityName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                }
                            }
                            .frame(height: 220)
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
        guard let lat = latitude, let lon = longitude else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        ))
    }

    private var service: FamilyJourneyService {
        FamilyJourneyService(modelContext: modelContext)
    }

    private func saveLocation() {
        guard let lat = latitude, let lon = longitude else { return }
        
        let targetMember: FamilyMember
        if let selectedMemberID {
            guard let existing = members.first(where: { $0.id == selectedMemberID }) else { return }
            targetMember = existing
        } else {
            targetMember = service.createFamilyMember(name: newMemberName)
        }
        
        service.insertLocation(
            cityName: cityName,
            latitude: lat,
            longitude: lon,
            timestamp: timestamp,
            note: note,
            member: targetMember
        )
        
        dismiss()
    }
}

#Preview {
    AddLocationSheet()
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
