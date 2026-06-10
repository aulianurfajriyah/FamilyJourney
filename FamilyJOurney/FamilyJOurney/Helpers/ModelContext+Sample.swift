//
//  ModelContext+Sample.swift
//  FamilyJOurney
//
//  Created by Antigravity on 10/06/26.
//

import Foundation
import SwiftData

extension ModelContext {
    // This helper inserts sample records through the SwiftData model context.
    func insertSampleLocationRecords() {
        for record in SampleLocationRecords.makeRecords() {
            insert(record)
        }
    }
}
