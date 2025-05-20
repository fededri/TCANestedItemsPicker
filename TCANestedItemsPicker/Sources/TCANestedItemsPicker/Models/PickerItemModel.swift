//
//  File.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

struct PickerItemModel<ID: Hashable & Sendable>: Identifiable, Equatable {
    let id: ID
    let displayName: String
    let hasChildren: Bool
}

