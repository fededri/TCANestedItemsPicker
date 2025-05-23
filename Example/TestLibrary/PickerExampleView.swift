//
//  ContentView.swift
//  TestLibrary
//
//  Created by Federico Torres on 20/05/25.
//

import SwiftUI
import TCANestedItemsPicker
import ComposableArchitecture

struct PickerExampleView: View {
    var body: some View {
        NavigationView {
            VStack {
                NestedItemsPickerView(
                    store: Store(
                        initialState: NestedItemsPicker<String>.State(
                            id: "root",
                            includeChildrenEnabled: true,
                            showSelectedChildrenCount: true,
                            title: "Categories"
                        )
                    ) {
                        NestedItemsPicker<String>(repository: exampleRepository)
                    },
                    emptyStateContent: { reason in
                        EmptyStateView(reason: reason)
                    }
                )
            }
        }
    }
}

// MARK: - Previews
#Preview("Picker Example") {
    PickerExampleView()
} 
