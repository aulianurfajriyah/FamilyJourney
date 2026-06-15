//
//  FamilyLegendSheet.swift
//  FamilyJOurney
//
//  Created by Antigravity on 11/06/26.
//

import SwiftData
import SwiftUI

struct FamilyLegendSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    
    // Binding to the set of hidden member IDs maintained on the parent map screen.
    @Binding var hiddenMemberIDs: Set<UUID>

    // Navigation and presenting states
    @State private var isShowingAddMember = false
    @State private var editingMember: FamilyMember?

    private var memberService: FamilyMemberService {
        FamilyMemberService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            Group {
                if members.isEmpty {
                    ContentUnavailableView(
                        "No Family Members",
                        systemImage: "person.3.sequence",
                        description: Text("Add a member using the + button above, or add location stops first.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(members) { member in
                                let isVisibleBinding = Binding<Bool>(
                                    get: { !hiddenMemberIDs.contains(member.id) },
                                    set: { isVisible in
                                        if isVisible {
                                            hiddenMemberIDs.remove(member.id)
                                        } else {
                                            hiddenMemberIDs.insert(member.id)
                                        }
                                    }
                                )

                                Toggle(isOn: isVisibleBinding) {
                                    HStack(spacing: 12) {
                                        // Display member image or fallback emoji in a styled circular background matching their route color
                                        MemberAvatarView(member: member, size: 36, borderWidth: 1.5)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.name)
                                                .font(.body) // Dynamic Type compliance
                                                .foregroundStyle(.primary)
                                            
                                            let count = member.locations?.count ?? 0
                                            Text("\(count) \(count == 1 ? "stop" : "stops")")
                                                .font(.caption) // Dynamic Type compliance
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        memberService.deleteMember(member: member)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingMember = member
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        } header: {
                            Text("Swipe row left to Delete / right to Edit")
                        }
                    }
                }
            }
            .navigationTitle("Journey Legend")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden) // Liquid glass styling
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.body)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddMember = true
                    } label: {
                        Label("Add Member", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddMember) {
                AddMemberSheet()
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingMember) { member in
                EditMemberSheet(member: member)
                    .presentationDetents([.large])
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(30)
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    FamilyLegendSheet(hiddenMemberIDs: .constant([]))
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
