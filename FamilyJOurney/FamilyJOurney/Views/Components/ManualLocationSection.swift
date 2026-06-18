//
//  ManualLocationSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import MapKit
import SwiftUI

struct ManualLocationSection: View {
    @Binding var cityName: String
    @Binding var latitudeString: String
    @Binding var longitudeString: String
    @Binding var mapCameraPosition: MapCameraPosition

    private var manualLatitude: Double? {
        Double(latitudeString)
    }

    private var manualLongitude: Double? {
        Double(longitudeString)
    }

    var body: some View {
        Group {
            TextField("City Name (e.g. Bandung)", text: $cityName)
                .autocorrectionDisabled()
                .font(.body) // Dynamic Type compliance

            TextField("Latitude (e.g. -6.9175)", text: $latitudeString)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .font(.body) // Dynamic Type compliance
                .onChange(of: latitudeString) { _, _ in
                    updateManualMapCamera()
                }

            TextField("Longitude (e.g. 107.6191)", text: $longitudeString)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .font(.body) // Dynamic Type compliance
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
        }
    }

    private func updateManualMapCamera() {
        guard let lat = manualLatitude, let lon = manualLongitude else { return }
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
}
