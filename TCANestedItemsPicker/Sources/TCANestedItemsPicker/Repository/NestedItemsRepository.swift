//
//  File.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import ComposableArchitecture

struct NestedItemsRepository<ID: Hashable & Sendable> {
    typealias Model = PickerItemModel<ID>

    // returns all items that should be showed in the first page
    var rootItems: @Sendable () async throws  -> IdentifiedArrayOf<Model>
    /// returns the direct children of a given parent item (only the first descendant level)
    var childrenItemsByParentId: @Sendable (ID) async throws -> IdentifiedArrayOf<Model>

    /// given an item ID, returns the ID of all its children (not only the first level)
    var allDescendantsIDs: @Sendable (ID) async -> [ID]
    /// Searches through all available items for a match in the display name.
    var searchItems: @Sendable (String) async -> IdentifiedArrayOf<Model>
}
