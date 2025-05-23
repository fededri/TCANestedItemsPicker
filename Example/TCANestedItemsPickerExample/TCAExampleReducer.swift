//
//  ContentView.swift
//  TCANestedItemsPickerExample
//
//  Created by Federico Torres on 20/05/25.
//

import Foundation
import ComposableArchitecture
import TCANestedItemsPicker
import SwiftUI

@Reducer
struct NestedPickerExampleReducer: Reducer {
    typealias ID = String
    @Dependency(\.nestedItemsRepository) private var repository

    @ObservableState
    struct State: Equatable {
        var pickerState: NestedItemsPicker<ID>.State
        var customTitle: String = "Items Picker"
        
        @Shared var allSelectedItems: Set<ID>

        init() {
            // Create a shared set with a specific in-memory key to avoid collisions
            let sharedSet: Shared<Set<ID>> = Shared(wrappedValue: [], .inMemory("TCAExample"))

            self._allSelectedItems = sharedSet
            
            pickerState = NestedItemsPicker<ID>.State(
                id: "root",
                includeChildrenEnabled: true,
                showSelectedChildrenCount: true,
                showSearchBar: true,
                title: "Items Picker",
                allSelectedItems: sharedSet
            )
        }
    }
    
    enum Action {
        case picker(NestedItemsPicker<ID>.Action)
        case clearAllSelections
        case setCustomTitle(String)
        case toggleIncludeChildrenDefault(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.pickerState, action: \.picker) {
            NestedItemsPicker<ID>(repository: repository)
        }
        
        Reduce { state, action in
            switch action {
            case .clearAllSelections:
                // Clear all selections by directly modifying the shared state
                state.$allSelectedItems.withLock { selectedSet in
                    selectedSet.removeAll()
                }
                return .none
                
            case .setCustomTitle(let title):
                state.customTitle = title
                state.pickerState.title = title
                return .none
                
            case .toggleIncludeChildrenDefault(let enabled):
                state.pickerState.includeChildrenEnabled = enabled
                return .none
                
            case .picker:
                return .none
            }
        }
    }
} 
