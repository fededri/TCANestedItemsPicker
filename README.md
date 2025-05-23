# TCANestedItemsPicker
[![Swift Version](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B-blue.svg)](https://developer.apple.com/iOS)
[![TCA Version](https://img.shields.io/badge/TCA-1.18%2B-purple.svg)](https://github.com/pointfreeco/swift-composable-architecture)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT) 
<!-- Add other relevant badges like build status -->



A powerful, reusable SwiftUI component built with **The Composable Architecture (TCA)** for selecting items from hierarchical (tree-like) data structures. Perfect for categories, organizational structures, file systems, or any nested data that requires user selection.

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

## 📋 Requirements

- **iOS**: 16.0+
- **Swift**: 6.0+
- **Dependencies**: [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.18.0+

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
## 📚 Detailed Usage

### State Configuration Options

```swift
NestedItemsPicker<String>.State(
    id: "root",                           // the ID used for your root item
    includeChildrenEnabled: true,         // Enable recursive selection
    showSelectedChildrenCount: true,      // Show count of selected children
    showSearchBar: true,                  // Enable search functionality
    title: "Select Items",               // Navigation title
    allSelectedItems: Shared<Set<ID>> // Shared selection state
)
```

### Advanced Usage with Multiple Pickers

Share selection state across multiple picker features using TCA dependencies:

```swift
// Shared app state for selection coordination
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var sharedSelection: Set<String> = []
        var categoryPicker = CategoryPickerFeature.State()
        var locationPicker = LocationPickerFeature.State()
        
        init() {
            // Initialize both pickers with shared selection
            let sharedState = Shared(value: sharedSelection)
            categoryPicker.pickerState.$allSelectedItems = sharedState
            locationPicker.pickerState.$allSelectedItems = sharedState
        }
    }
    
    enum Action {
        case categoryPicker(CategoryPickerFeature.Action)
        case locationPicker(LocationPickerFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.categoryPicker, action: \.categoryPicker) {
            CategoryPickerFeature()
        }
        Scope(state: \.locationPicker, action: \.locationPicker) {
            LocationPickerFeature()
        }
        
        Reduce { state, action in
            // Sync selection changes across pickers
            switch action {
            case .categoryPicker, .locationPicker:
                state.sharedSelection = state.categoryPicker.selectedCategories.union(
                    state.locationPicker.selectedLocations
                )
                return .none
            }
        }
    }
}

// App view with multiple pickers
struct MultiPickerView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        TabView {
            CategoryPickerView(
                store: store.scope(state: \.categoryPicker, action: \.categoryPicker)
            )
            .tabItem { Label("Categories", systemImage: "list.bullet") }
            
            LocationPickerView(
                store: store.scope(state: \.locationPicker, action: \.locationPicker)
            )
            .tabItem { Label("Locations", systemImage: "location") }
        }
    }
}
```

## 🏗️ Advanced Dependency Patterns

### Environment-Specific Repository Configurations

Configure different repositories for different environments:

```swift
extension DependencyValues {
    var categoryRepository: NestedItemsRepository<String> {
        get { self[CategoryRepositoryKey.self] }
        set { self[CategoryRepositoryKey.self] = newValue }
    }
}

private enum CategoryRepositoryKey: DependencyKey {
    static let liveValue = NestedItemsRepository<String>.live
    static let testValue = NestedItemsRepository<String>.mock
    static let previewValue = NestedItemsRepository<String>.preview
}

// Different implementations for different environments
extension NestedItemsRepository where ID == String {
    // Production with real API calls
    static let live = NestedItemsRepository<String>(/* production implementation */)
    
    // Fast mock for unit tests
    static let mock = NestedItemsRepository<String>(/* mock implementation */)
    
    // Rich preview data for SwiftUI previews
    static let preview = NestedItemsRepository<String>(
        childrenItemsByParentId: { parentId in
            // Return rich, realistic preview data
            let previewData = PreviewDataGenerator.generateCategories(for: parentId)
            return IdentifiedArray(uniqueElements: previewData)
        },
        allDescendantsIDs: { parentId in
            return PreviewDataGenerator.getAllDescendants(for: parentId)
        },
        searchItems: { query in
            return PreviewDataGenerator.searchCategories(query: query)
        }
    )
}
```

### Custom Dependency with Configuration

Create a repository with configurable behavior:

```swift
struct CategoryRepositoryConfiguration {
    let enableCaching: Bool
    let maxCacheSize: Int
    let apiTimeout: TimeInterval
}

extension DependencyValues {
    var categoryRepositoryConfig: CategoryRepositoryConfiguration {
        get { self[CategoryRepositoryConfigKey.self] }
        set { self[CategoryRepositoryConfigKey.self] = newValue }
    }
}

private enum CategoryRepositoryConfigKey: DependencyKey {
    static let liveValue = CategoryRepositoryConfiguration(
        enableCaching: true,
        maxCacheSize: 1000,
        apiTimeout: 30.0
    )
    static let testValue = CategoryRepositoryConfiguration(
        enableCaching: false,
        maxCacheSize: 0,
        apiTimeout: 1.0
    )
}

// Repository that uses configuration
extension NestedItemsRepository where ID == String {
    static var live: Self {
        @Dependency(\.categoryRepositoryConfig) var config
        @Dependency(\.apiClient) var apiClient
        
        return NestedItemsRepository<String>(
            childrenItemsByParentId: { parentId in
                if config.enableCaching, let cached = CategoryCache.get(parentId) {
                    return cached
                }
                
                let result = try await apiClient.fetchCategories(
                    parentId: parentId,
                    timeout: config.apiTimeout
                )
                
                if config.enableCaching {
                    CategoryCache.store(result, for: parentId, maxSize: config.maxCacheSize)
                }
                
                return result
            },
            allDescendantsIDs: { parentId in
                return await apiClient.fetchAllDescendants(parentId: parentId)
            },
            searchItems: { query in
                return await apiClient.searchCategories(query: query)
            }
        )
    }
}
```

## 🧪 Testing

The library is designed with TCA's testing philosophy in mind:

```swift
@Test
func testItemSelection() async {
    let store = TestStore(
        initialState: NestedItemsPicker<String>.State(
            id: "root",
            showSelectedChildrenCount: false,
            allSelectedItems: Shared(value: [])
        )
    ) {
        NestedItemsPicker<String>(repository: .mock)
    }
    
    // Test selection behavior
    await store.send(.toggleSelection) {
        $0.allSelectedItems = ["root"]
    }
}
```

## 🎨 Customization

### Custom Row Views

While the library provides a default UI, you can create your own views and reuse library's ```NestedItemsPicker```reducer:

## 📖 API Reference

### `PickerItemModel<ID>`

```swift
public struct PickerItemModel<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let displayName: String
    public let hasChildren: Bool
}
```

### `NestedItemsRepository<ID>`

```swift
public struct NestedItemsRepository<ID: Hashable & Sendable>: Sendable {
    public var childrenItemsByParentId: @Sendable (ID) async throws -> IdentifiedArrayOf<Model>
    public var allDescendantsIDs: @Sendable (ID) async -> [ID]
    public var searchItems: @Sendable (String) async -> IdentifiedArrayOf<Model>
}
```

### `EmptyStateReason`

```swift
public enum EmptyStateReason {
    case noChildrenFound          // Item has no children
    case searchResultEmpty        // Search returned no results
    case errorLoadingChildren     // Failed to load children
    case errorSearchingItems      // Search operation failed
}
```

## 🤝 Contributing

Please feel free to submit issues, feature requests, or pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with using [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by Point-Free.
