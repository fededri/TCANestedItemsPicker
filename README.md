# TCANestedItemsPicker
[![Swift Version](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B-blue.svg)](https://developer.apple.com/iOS)
[![TCA Version](https://img.shields.io/badge/TCA-1.18%2B-purple.svg)](https://github.com/pointfreeco/swift-composable-architecture)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)


A powerful, reusable SwiftUI component built with **The Composable Architecture (TCA)** for selecting items from hierarchical (tree-like) data structures. Perfect for categories, organizational structures, file systems, or any nested data that requires user selection.

https://github.com/user-attachments/assets/34f24ade-9f72-444a-8686-19ebff524592

## ✨ Features

- **🌳 Hierarchical Display**: Expandable, nested list format with navigation between levels
- **🎯 Flexible Selection**: Single or multiple item selection with visual indicators
- **🔄 Recursive Selection**: Automatically select/deselect all child items when parent is toggled
- **🔍 Smart Search**: Built-in search functionality with debounced input
- **📊 Selection Count**: Display the number of selected descendants for parent items
- **⚡ TCA Powered**: Leverages TCA for predictable state management and easy testing
- **🔗 Shared State**: Use `@Shared` state to coordinate selection across multiple picker instances
- **💪 Type-Safe**: Generic implementation supporting any `Hashable` identifier type
- **🎨 Customizable**: Custom empty states and flexible UI customization
- **📱 Native Feel**: Loading states, error handling, and smooth navigation

## 🏗️ Architecture

The library follows TCA principles with clear separation of concerns:

- **`NestedItemsPicker`**: Main TCA reducer managing picker logic and state
- **`NestedItemsPickerView`**: SwiftUI view providing the user interface
- **`NestedItemsRepository`**: Protocol for data access and business logic
- **`PickerItemModel`**: Core data model representing hierarchical items

## 📋 Versioning

- **iOS**: 16.0+
- **Swift**: 6.0+
- **Dependencies**: [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.19.1+

## 📦 Installation

### Swift Package Manager

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/fededri/TCANestedItemsPicker`
3. Choose the desired version or branch

## 🚀 Quick Start

### 1. Import the Library

```swift
import TCANestedItemsPicker
```

### 2. Define Your Data Model

```swift
// Your hierarchical data (example: categories)
struct Category {
    let id: String
    let name: String
    let parentId: String?
    let hasSubcategories: Bool
}
```

### 3. Create a Repository with TCA Dependencies

Define your repository as a dependency for better testability and separation of concerns:

```swift
import ComposableArchitecture

// MARK: - Dependency Definition
extension DependencyValues {
    var categoryRepository: NestedItemsRepository<String> {
        get { self[CategoryRepositoryKey.self] }
        set { self[CategoryRepositoryKey.self] = newValue }
    }
}

private enum CategoryRepositoryKey: DependencyKey {
    static let liveValue = NestedItemsRepository<String>.live
    static let testValue = NestedItemsRepository<String>.mock
    static let previewValue = NestedItemsRepository<String>.mock
}

// MARK: - Repository Implementations
extension NestedItemsRepository where ID == String {
    
    // Live implementation for production
    static let live = NestedItemsRepository<String>(
        childrenItemsByParentId: { parentId in
            // Fetch direct children from your API/Database
            let children = await CategoryService.fetchChildren(for: parentId)
            return IdentifiedArray(uniqueElements: children.map { category in
                PickerItemModel(
                    id: category.id,
                    displayName: category.name,
                    hasChildren: category.hasSubcategories
                )
            })
        },
        allDescendantsIDs: { parentId in
            // Return ALL descendant IDs (recursive)
            return await CategoryService.fetchAllDescendantIDs(for: parentId)
        },
        searchItems: { query in
            // Search through all available items
            let results = await CategoryService.search(query: query)
            return IdentifiedArray(uniqueElements: results.map { category in
                PickerItemModel(
                    id: category.id,
                    displayName: category.name,
                    hasChildren: category.hasSubcategories
                )
            })
        }
    )
    
    // Mock implementation for testing and previews
    static let mock = ...
}
```

### 4. Use in Your TCA Feature

Inject the repository dependency into your feature reducer:

```swift
@Reducer
struct CategoryPickerFeature {
    @Dependency(\.categoryRepository) var categoryRepository

    @ObservableState
    struct State: Equatable {
        var pickerState: NestedItemsPicker<ID>.State        
        @Shared var allSelectedItems: Set<ID>

        init() {
            // Create a shared set with a specific in-memory key to avoid collisions
            let sharedSet: Shared<Set<ID>> = Shared(wrappedValue: [], .inMemory("TCAExample"))

            self._allSelectedItems = sharedSet
            
            pickerState = NestedItemsPicker<ID>.State(
                id: "root",
                includeChildrenEnabled: true,
                showSelectedChildrenCount: true,
                showSearchBar: true,
                title: "Items Picker",
                allSelectedItems: sharedSet
            )
        }
    }
    
    enum Action {
        case picker(NestedItemsPicker<String>.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.pickerState, action: \.picker) {
            NestedItemsPicker<String>(repository: categoryRepository)
        }
        
        Reduce { state, action in
            switch action {
            case .picker:
                // handle picker actions
                return .none
            }
        }
    }
}

// MARK: - SwiftUI View
struct CategoryPickerView: View {
    let store: StoreOf<CategoryPickerFeature>
    
    var body: some View {
        NavigationView {
            NestedItemsPickerView(
                store: store.scope(state: \.pickerState, action: \.picker),
                emptyStateContent: { reason in
                    EmptyStateView(reason: reason)
                }
            )
        }
        .onAppear {
            store.send(.loadRootCategories)
        }
    }
}
```

## 🧪 Testing

The library is designed with TCA's testing philosophy in mind:

```swift
@Test
func testItemSelection() async {
    let store = TestStore(
        initialState: CategoryPickerFeature.State()
    ) {
        CategoryPickerFeature()
    }
    // optionally modify your mock repository
    
    // Test selection behavior
    await store.send(.picker.toggleSelection) {
        // test changes in your state
    }
}
```

## 🎨 Customization

While the library provides a default UI, you can create your own views and reuse library's ```NestedItemsPicker```reducer

## 🤝 Contributing

Please feel free to submit issues, feature requests, or pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built using [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by Point-Free.
