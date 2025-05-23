//
//  ContentView.swift
//  TestLibrary
//
//  Created by Federico Torres on 20/05/25.
//

import Foundation
import ComposableArchitecture
import TCANestedItemsPicker

enum NestedItemsRepositoryKey: DependencyKey {
    static let liveValue: NestedItemsRepository<String> = exampleRepository
    
    static let testValue: NestedItemsRepository<String> = NestedItemsRepository<String>(
        childrenItemsByParentId: { _ in return IdentifiedArray() },
        allDescendantsIDs: { _ in return [] },
        searchItems: { _ in return IdentifiedArray() }
    )
}

extension DependencyValues {
    var nestedItemsRepository: NestedItemsRepository<String> {
        get { self[NestedItemsRepositoryKey.self] }
        set { self[NestedItemsRepositoryKey.self] = newValue }
    }
} 
