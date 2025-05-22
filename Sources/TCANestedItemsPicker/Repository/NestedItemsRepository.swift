//
//  NestedItemsRepository.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import ComposableArchitecture

public struct NestedItemsRepository<ID: Hashable & Sendable>: Sendable {
    public typealias Model = PickerItemModel<ID>

    /// returns the direct children of a given parent item (only the first descendant level)
    public var childrenItemsByParentId: @Sendable (ID) async throws -> IdentifiedArrayOf<Model>

    /// given an item ID, returns the ID of all its children (not only the first level)
    public var allDescendantsIDs: @Sendable (ID) async -> [ID]
    /// Searches through all available items for a match in the display name.
    public var searchItems: @Sendable (String) async -> IdentifiedArrayOf<Model>
    
    public init(
        childrenItemsByParentId: @escaping @Sendable (ID) async throws -> IdentifiedArrayOf<Model>,
        allDescendantsIDs: @escaping @Sendable (ID) async -> [ID],
        searchItems: @escaping @Sendable (String) async -> IdentifiedArrayOf<Model>
    ) {
        self.childrenItemsByParentId = childrenItemsByParentId
        self.allDescendantsIDs = allDescendantsIDs
        self.searchItems = searchItems
    }
}
