//
//  FamilyMapScreen+Search.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Search Functionality
extension FamilyMapScreen {

    /// Filters location records and saved locations by the current search text.
    var searchResults: [SearchResultItem] {
        guard !searchText.isEmpty else { return [] }

        let keyword = searchText.lowercased()
        var results: [SearchResultItem] = []

        // 1. Filter Location Records (Family Member Stops)
        for record in locationRecords {
            let cityNameMatches = record.cityName.lowercased().contains(keyword)
            let memberNameMatches = record.member?.name.lowercased().contains(keyword) ?? false
            if cityNameMatches || memberNameMatches {
                results.append(SearchResultItem(
                    id: record.id.uuidString,
                    title: record.cityName,
                    subtitle: "Stop by \(record.member?.name ?? "Unknown")",
                    systemImage: "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
                ))
            }
        }

        for location in savedLocations {
            if location.name.lowercased().contains(keyword) {
                results.append(SearchResultItem(
                    id: location.id.uuidString,
                    title: location.name,
                    subtitle: "Preset Location",
                    systemImage: "mappin.and.ellipse",
                    coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                ))
            }
        }

        return results
    }

    /// Animates the camera to a tapped search result and auto-selects the record if applicable.
    func flyTo(_ item: SearchResultItem) {
        withAnimation(.easeInOut(duration: 1.2)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: item.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }

        if let recordUUID = UUID(uuidString: item.id),
           locationRecords.contains(where: { $0.id == recordUUID }) {
            selectedRecordID = recordUUID
        }

        
        isSearchFieldFocused = false
        searchText = ""
    }

    /// Resolves a MapKit search completion to coordinates and animates the camera there.
    func flyTo(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }

            withAnimation(.easeInOut(duration: 1.2)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }

        
        isSearchFieldFocused = false
        searchText = ""
    }
}
