//
//  PickerItemModel.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

public struct PickerItemModel<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let displayName: String
    public let hasChildren: Bool
    
    public init(id: ID, displayName: String, hasChildren: Bool) {
        self.id = id
        self.displayName = displayName
        self.hasChildren = hasChildren
    }
}

