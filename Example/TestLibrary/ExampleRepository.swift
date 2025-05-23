//
//  ContentView.swift
//  TestLibrary
//
//  Created by Federico Torres on 20/05/25.
//

import Foundation
import TCANestedItemsPicker
import ComposableArchitecture

// Create a repository with the mock data
let exampleRepository = NestedItemsRepository<String>(
    childrenItemsByParentId: { parentId in
        try? await Task.sleep(for: .milliseconds(300))
        if parentId == "root" {
            return IdentifiedArray(uniqueElements: exampleItems)
        }
        return IdentifiedArray(uniqueElements: getMockChildren(for: parentId))
    },
    allDescendantsIDs: { parentId in
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
    },
    searchItems: { query in
        try? await Task.sleep(for: .milliseconds(300))
        if query.isEmpty {
            return []
        }
        let lowercasedQuery = query.lowercased()
        let results = allMockItems.filter {
            $0.displayName.lowercased().contains(lowercasedQuery)
        }
        return IdentifiedArray(uniqueElements: results)
    }
) 
