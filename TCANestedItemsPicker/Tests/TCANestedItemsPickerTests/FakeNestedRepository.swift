//
//  FakeNestedRepository.swift
//  ItemsPickerTests
//
//  Created by Federico Torres on 16/05/25.
//

import ComposableArchitecture
@testable import ItemsPicker
import Foundation

let rootItems: [PickerItemModel<String>] = [
    PickerItemModel(id: "1", displayName: "Root 1", hasChildren: true),
    PickerItemModel(id: "2", displayName: "Root 2", hasChildren: true),
    PickerItemModel(id: "3", displayName: "Root 3", hasChildren: false),
]

let allMockItems: [PickerItemModel<String>] = [
    PickerItemModel(id: "1", displayName: "Root 1", hasChildren: true),
    PickerItemModel(id: "2", displayName: "Root 2", hasChildren: true),
    PickerItemModel(id: "3", displayName: "Root 3", hasChildren: false),
    PickerItemModel(id: "11", displayName: "Item 1.1", hasChildren: true),
    PickerItemModel(id: "12", displayName: "Item 1.2", hasChildren: true),
    PickerItemModel(id: "13", displayName: "Item 1.3", hasChildren: false),
    PickerItemModel(id: "21", displayName: "Item 2.1", hasChildren: true),
    PickerItemModel(id: "22", displayName: "Item 2.2", hasChildren: false),
    PickerItemModel(id: "111", displayName: "Item 1.1.1", hasChildren: false),
    PickerItemModel(id: "112", displayName: "Item 1.1.2", hasChildren: true),
    PickerItemModel(id: "121", displayName: "Item 1.2.1", hasChildren: false),
    PickerItemModel(id: "122", displayName: "Item 1.2.2", hasChildren: false),
    PickerItemModel(id: "123", displayName: "Item 1.2.3", hasChildren: false),
    PickerItemModel(id: "211", displayName: "Item 2.1.1", hasChildren: false),
    PickerItemModel(id: "212", displayName: "Item 2.1.2", hasChildren: false),
    PickerItemModel(id: "1121", displayName: "Item 1.1.2.1", hasChildren: false),
    PickerItemModel(id: "1122", displayName: "Item 1.1.2.2", hasChildren: false),
]

@Sendable func getMockChildren(for parentId: String) -> [PickerItemModel<String>] {
    switch parentId {
    case "root":
        return rootItems
    case "1":
        return [
            PickerItemModel(id: "11", displayName: "Item 1.1", hasChildren: true),
            PickerItemModel(id: "12", displayName: "Item 1.2", hasChildren: true),
            PickerItemModel(id: "13", displayName: "Item 1.3", hasChildren: false),
        ]
    case "2":
        return [
            PickerItemModel(id: "21", displayName: "Item 2.1", hasChildren: true),
            PickerItemModel(id: "22", displayName: "Item 2.2", hasChildren: false),
        ]
    case "11":
        return [
            PickerItemModel(id: "111", displayName: "Item 1.1.1", hasChildren: false),
            PickerItemModel(id: "112", displayName: "Item 1.1.2", hasChildren: true),
        ]
    case "12":
        return [
            PickerItemModel(id: "121", displayName: "Item 1.2.1", hasChildren: false),
            PickerItemModel(id: "122", displayName: "Item 1.2.2", hasChildren: false),
            PickerItemModel(id: "123", displayName: "Item 1.2.3", hasChildren: false),
        ]
    case "21":
        return [
            PickerItemModel(id: "211", displayName: "Item 2.1.1", hasChildren: false),
            PickerItemModel(id: "212", displayName: "Item 2.1.2", hasChildren: false),
        ]
    case "112":
        return [
            PickerItemModel(id: "1121", displayName: "Item 1.1.2.1", hasChildren: false),
            PickerItemModel(id: "1122", displayName: "Item 1.1.2.2", hasChildren: false),
        ]
    default:
        return []
    }
}


let fakeNestedRepository = NestedItemsRepository<String>(
    rootItems: {
        return IdentifiedArray(uniqueElements: rootItems)
    },
    childrenItemsByParentId: { parentId in
       return IdentifiedArray(uniqueElements: getMockChildren(for: parentId))
    }, allDescendantsIDs: { parentId in
        func findDescendants(currentParentId: String) -> Set<String> {
            var collectedIDs = Set<String>()
            let children = getMockChildren(for: currentParentId)

            for child in children {
                collectedIDs.insert(child.id)
                if child.hasChildren {
                    collectedIDs.formUnion(findDescendants(currentParentId: child.id))
                }
            }
            return collectedIDs
        }

        let allIDs = findDescendants(currentParentId: parentId)
        return Array(allIDs)
    }, searchItems: { query in
        try? await Task.sleep(for: .milliseconds(300))
        if query.isEmpty {
            return []
        }
        let lowercasedQuery = query.lowercased()
        let results = allMockItems.filter {
            $0.displayName.lowercased().contains(lowercasedQuery)
        }
        return IdentifiedArray(uniqueElements: results)
    })
