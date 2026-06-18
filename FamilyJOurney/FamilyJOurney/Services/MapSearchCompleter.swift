//
//  MapSearchCompleter.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import Combine
import MapKit

class MapSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func updateQuery(_ query: String) {
        if query.isEmpty {
            completions = []
        } else {
            completer.queryFragment = query
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        DispatchQueue.main.async {
            self.completions = results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Map search completer error: \(error.localizedDescription)")
    }
}
