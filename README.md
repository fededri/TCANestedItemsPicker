# TCANestedItemsPicker
[![Swift Version](https://img.shields.io/badge/Swift-5.7%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20macOS%2013%2B-blue.svg)](https://developer.apple.com/macOS)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT) 
<!-- Add other relevant badges like build status -->



A reusable SwiftUI component built with **The Composable Architecture (TCA)** for selecting one or more items from a hierarchical (tree) data structure. It supports optional recursive selection/deselection of child items when a parent is toggled.

## Features

*   Displays items in an expandable, nested list format.
*   Supports single or multiple item selection.
*   **Recursive Selection:** Optionally select/deselect all descendants when a parent item is selected/deselected.
*   **Search:** Built-in functionality to filter the hierarchy.
*   **Selected Count:** Optionally display the number of selected descendants for a parent item.
*   **TCA Powered:** Leverages TCA for state management, side effects, and testing.
*   **Flexible Selection Scope:** Uses TCA's `@Shared` state, allowing multiple picker instances to share or maintain independent selection sets based on the provided shared key.

## Requirements

*   iOS 16.0+ / macOS 13.0+
*   Swift 5.7+
*   [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA) library 1.18.0

## Installation

You can add `TCANestedItemsPicker` to your project using Swift Package Manager.

1.  In Xcode, select **File > Add Packages...**
2.  Enter the repository URL: `https://github.com/fededri/TCANestedItemsPicker`
3.  Choose the desired version or branch.

### 2. Import the library

```swift
import TCANestedItemsPicker
```

### 3. Create a repository

Implement the `NestedItemsRepository` to provide data to the picker. 

```swift
let myRepository = NestedItemsRepository<String>(
    childrenItemsByParentId: { parentId in
        // Return direct children for a given parent ID
    },
    allDescendantsIDs: { parentId in
        // Return all descendant IDs for a given parent ID, including children from deep levels
    },
    searchItems: { query in
        // Return search results for a given query
    }
)
```
You can use TCA Dependency library too.

### 4. Create the picker view

```swift
NestedItemsPickerView(
    store: Store(
        initialState: NestedItemsPicker<String>.State(
            id: "root",
            initialItems: yourInitialItems,
            includeChildrenEnabled: true, // optional
            showSelectedChildrenCount: true, // optional
            title: "Categories",
            allSelectedItems: Shared(yourSelectedItemsSet)
        )
    ) {
        NestedItemsPicker<String>(repository: myRepository)
    },
    emptyStateContent: { reason in
        // Your custom empty state view
        EmptyStateView(reason: reason)
    }
)
```

## Example

Check out `TCANestedItemsPickerExampleApp.swift` in this repository for a complete working example.

The example includes:

1. A complete mock data structure with multiple nested levels
2. Implementation of all repository functions
3. An empty state UI
4. Integration with a SwiftUI app

## Understanding the Library

### Key Components

1. **NestedItemsPickerView**: The main SwiftUI view that displays the picker UI
2. **NestedItemsPicker**: The TCA reducer that manages the picker state and logic
3. **NestedItemsRepository**: The protocol that provides data to the picker
4. **PickerItemModel**: The model representing an item in the picker

### Empty State Handling

The library allows you to customize empty states through the `emptyStateContent` parameter, which accepts a view builder that receives an `EmptyStateReason` enum:

- `.noChildrenFound`: When an item has no children
- `.searchResultEmpty`: When a search returns no results
- `.errorLoadingChildren`: When there's an error loading children
- `.errorSearchingItems`: When there's an error during search
