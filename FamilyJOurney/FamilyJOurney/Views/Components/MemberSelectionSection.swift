//
//  MemberSelectionSection.swift
//  FamilyJOurney
//
//  Created by Antigravity on 15/06/26.
//

import SwiftUI

struct MemberSelectionSection: View {
    @Binding var selectedMemberID: UUID?
    @Binding var newMemberName: String
    let members: [FamilyMember]
    
    var body: some View {
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
    }
}
