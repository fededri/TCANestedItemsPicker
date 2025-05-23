//
//  ContentView.swift
//  TCANestedItemsPickerExample
//
//  Created by Federico Torres on 20/05/25.
//

import Foundation
import TCANestedItemsPicker
import ComposableArchitecture

// Example mock data
let exampleItems: [PickerItemModel<String>] = [
    PickerItemModel(id: "1", displayName: "Food", hasChildren: true),
    PickerItemModel(id: "2", displayName: "Technology", hasChildren: true),
    PickerItemModel(id: "3", displayName: "Sports", hasChildren: true),
    PickerItemModel(id: "4", displayName: "Books", hasChildren: false),
]

func getMockChildren(for parentId: String) -> [PickerItemModel<String>] {
    switch parentId {
    case "1": // Food
        return [
            PickerItemModel(id: "11", displayName: "Fruits", hasChildren: true),
            PickerItemModel(id: "12", displayName: "Vegetables", hasChildren: true),
            PickerItemModel(id: "13", displayName: "Grains", hasChildren: false),
            PickerItemModel(id: "14", displayName: "Proteins", hasChildren: false),
        ]
    case "2": // Technology
        return [
            PickerItemModel(id: "21", displayName: "Computers", hasChildren: true),
            PickerItemModel(id: "22", displayName: "Phones", hasChildren: true),
            PickerItemModel(id: "23", displayName: "Wearables", hasChildren: false),
        ]
    case "3": // Sports
        return [
            PickerItemModel(id: "31", displayName: "Team Sports", hasChildren: true),
            PickerItemModel(id: "32", displayName: "Individual Sports", hasChildren: true),
        ]
    case "11": // Fruits
        return [
            PickerItemModel(id: "111", displayName: "Apples", hasChildren: false),
            PickerItemModel(id: "112", displayName: "Bananas", hasChildren: false),
            PickerItemModel(id: "113", displayName: "Oranges", hasChildren: false),
            PickerItemModel(id: "114", displayName: "Berries", hasChildren: true),
        ]
    case "12": // Vegetables
        return [
            PickerItemModel(id: "121", displayName: "Leafy Greens", hasChildren: false),
            PickerItemModel(id: "122", displayName: "Root Vegetables", hasChildren: false),
            PickerItemModel(id: "123", displayName: "Cruciferous", hasChildren: false),
        ]
    case "21": // Computers
        return [
            PickerItemModel(id: "211", displayName: "Laptops", hasChildren: false),
            PickerItemModel(id: "212", displayName: "Desktops", hasChildren: false),
            PickerItemModel(id: "213", displayName: "Tablets", hasChildren: false),
        ]
    case "22": // Phones
        return [
            PickerItemModel(id: "221", displayName: "iOS", hasChildren: false),
            PickerItemModel(id: "222", displayName: "Android", hasChildren: false),
        ]
    case "31": // Team Sports
        return [
            PickerItemModel(id: "311", displayName: "Soccer", hasChildren: false),
            PickerItemModel(id: "312", displayName: "Basketball", hasChildren: false),
            PickerItemModel(id: "313", displayName: "Baseball", hasChildren: false),
        ]
    case "32": // Individual Sports
        return [
            PickerItemModel(id: "321", displayName: "Tennis", hasChildren: false),
            PickerItemModel(id: "322", displayName: "Swimming", hasChildren: false),
            PickerItemModel(id: "323", displayName: "Golf", hasChildren: false),
        ]
    case "114": // Berries
        return [
            PickerItemModel(id: "1141", displayName: "Strawberries", hasChildren: false),
            PickerItemModel(id: "1142", displayName: "Blueberries", hasChildren: false),
            PickerItemModel(id: "1143", displayName: "Raspberries", hasChildren: false),
        ]
    default:
        return []
    }
}

let allMockItems: [PickerItemModel<String>] = {
    var allItems = exampleItems
    
    func addChildren(for parentId: String) {
        let children = getMockChildren(for: parentId)
        allItems.append(contentsOf: children)
        
        for child in children where child.hasChildren {
            addChildren(for: child.id)
        }
    }
    
    for item in exampleItems where item.hasChildren {
        addChildren(for: item.id)
    }
    
    return allItems
}() 
