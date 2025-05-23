//
//  ContentView.swift
//  TestLibrary
//
//  Created by Federico Torres on 20/05/25.
//

import SwiftUI
import ComposableArchitecture
import TCANestedItemsPicker

struct TCAExampleView: View {
    @State private var customTitle = "Items Picker"
    
    let store: StoreOf<NestedPickerExampleReducer>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack {
                    selectedItemsSection
                    
                    pickerSection
                }
                .navigationTitle("TCA Demo")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            store.send(.clearAllSelections)
                        }
                    }
                }
            }
        }
    }
    
    private var selectedItemsSection: some View {
        VStack(alignment: .leading) {
            Text("Selected Items: \(store.allSelectedItems.count)")
                .font(.headline)
                .padding(.horizontal)
                .animation(.none, value: store.allSelectedItems.count)

            Text("Ids:")
                .font(.subheadline)
                .padding(.horizontal)

            ZStack(alignment: .leading) {
                if store.allSelectedItems.isEmpty {
                    Text("No items selected")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.horizontal)
                        .transition(.opacity)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(store.allSelectedItems).sorted(), id: \.self) { itemId in
                                Text(itemId)
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .transition(.scale.combined(with: .opacity))
                                    .id(itemId) // Important for animations
                            }
                        }
                        .padding(.horizontal)
                        .animation(.smooth, value: store.allSelectedItems)
                    }
                    .frame(height: 40)
                    .transition(.opacity)
                }
            }
            .animation(.smooth, value: store.allSelectedItems.isEmpty)
        }
        .padding(.vertical, 8)
    }
    
    private var pickerSection: some View {
        VStack {
            Divider()

            VStack {
                NestedItemsPickerView(
                    store: store.scope(
                        state: \.pickerState,
                        action: \.picker
                    ),
                    emptyStateContent: { reason in
                        EmptyStateView(reason: reason)
                    }
                )
            }
        }
    }
}
