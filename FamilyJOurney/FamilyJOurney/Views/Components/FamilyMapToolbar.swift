//
//  FamilyMapToolbar.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import SwiftUI

struct FamilyMapToolbar: ToolbarContent {
    let hasLocationRecords: Bool
    
    @Binding var isShowingAddLocationSheet: Bool
    @Binding var isShowingLegendSheet: Bool
    
    var onFit: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Fit", systemImage: "scope") {
                onFit()
            }
            .disabled(!hasLocationRecords)
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                isShowingAddLocationSheet = true
            } label: {
                Label("Add Location", systemImage: "plus")
            }
            
            Button {
                isShowingLegendSheet = true
            } label: {
                Label("Members", systemImage: "person.3.fill")
            }
        }
    }
}
