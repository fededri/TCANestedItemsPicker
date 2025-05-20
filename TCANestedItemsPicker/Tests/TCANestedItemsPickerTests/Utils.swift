//
//  Utils.swift
//  ItemsPickerTests
//
//  Created by Federico Torres on 16/05/25.
//

@testable import ItemsPicker
import ComposableArchitecture
import Foundation

// Use explicit String type for tests
internal func makeSharedState(identifier: String = "", initialValue: Set<String> = []) -> Shared<Set<String>> {
    // Removed explicit .inMemory identifier as it's often not needed for simple tests
    // and can sometimes cause issues if identifiers clash.
    return Shared(value: initialValue)
}

// MARK: - Test Factory Helpers

/// Creates a `PickerItemModel<String>` for testing.
/// If `displayName` is nil, it defaults to the `id`.
internal func makeItem(
    id: String,
    displayName: String? = nil,
    hasChildren: Bool = false
) -> PickerItemModel<String> {
    PickerItemModel<String>(
        id: id,
        displayName: displayName ?? id,
        hasChildren: hasChildren
    )
}

/// Creates an expected `NestedItemsPicker<String>.State` for assertions,
/// mimicking the logic in the reducer's `mapItemsToState`.
/// It uses the parent state's flags to configure the child state.
internal func makeExpectedNestedState(
    item: PickerItemModel<String>,
    parentState: NestedItemsPicker<String>.State
) -> NestedItemsPicker<String>.State {
    return NestedItemsPicker<String>.State(
        id: item.id,
        pickerModel: item,
        includeChildrenEnabled: parentState.includeChildrenEnabled,
        showSelectedChildrenCount: parentState.showSelectedChildrenCount,
        showSearchBar: parentState.showSearchBar,
        title: item.displayName,
        allSelectedItems: parentState.$allSelectedItems
    )
}
