//
//  NestedItemsPickerTests.swift
//  ItemsPickerTests
//
//  Created by Federico Torres on 16/05/25.
//

@testable import ItemsPicker
import Testing
import ComposableArchitecture
import Foundation


@Suite
@MainActor
struct NestedItemsPickerTests {
    @Test
    func testOnFirstAppear_initializesSearchAndFetchesChildren() async {
        let selectedItems = makeSharedState()

        let initialState = NestedItemsPicker<String>.State(
            id: "root",
            showSelectedChildrenCount: false,
            showSearchBar: true,
            allSelectedItems: selectedItems
        )
        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }

        await store.send(.onFirstAppear) {
            $0.searchItems = SearchItems<String>.State()
        }

        await store.receive(\.setItems) { state in
            state.nested = IdentifiedArray(uniqueElements: rootItems.map { pickerModel in
                makeExpectedNestedState(item: pickerModel, parentState: state)
            })

        }
    }

    // MARK: - Toggle

    @Test
    func testToggleSelection_whenIncludeChildrenDisabled_togglesOnlyParent() async {
        let itemId = "item1"
        let selectedItems = makeSharedState()
        let initialState = NestedItemsPicker<String>.State(
            id: itemId,
            includeChildrenEnabled: false,
            showSelectedChildrenCount: false,
            showSearchBar: false,
            title: "Item 1",
            allSelectedItems: selectedItems
        )
        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }

        store.assert { state in
            #expect(!state.isSelected)
            #expect(!state.allSelectedItems.contains(itemId))
        }

        await store.send(.toggleSelection) {
            $0.$allSelectedItems.withLock { $0 = Set([itemId]) }
        }

        await store.send(.toggleSelection) {
            $0.$allSelectedItems.withLock { $0 = [] }
        }
    }

    @Test
    func testToggleSelection_whenIncludeChildrenEnabled_selectsParentAndDescendants() async {
        let parentItem = rootItems.first { $0.id == "1" }!
        let parentId = parentItem.id

        let descendantIds = await fakeNestedRepository.allDescendantsIDs(parentId)
        let expectedSelectedChildrenCount = descendantIds.count

        let sharedSelectedItems = makeSharedState()

        let initialState = NestedItemsPicker<String>.State(
            id: parentId,
            pickerModel: parentItem,
            includeChildrenEnabled: true,
            selectedChildrenCount: SelectedChildrenCount<String>.State(
                allSelectedItems: sharedSelectedItems,
                item: parentItem,
                selectedChildrenCount: 0
            ),
            showSelectedChildrenCount: true,
            title: parentItem.displayName,
            allSelectedItems: sharedSelectedItems
        )

        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }
        store.exhaustivity = .off


        // Assert initial conditions.
        store.assert { state in
            #expect(!state.isSelected)
            #expect(state.allSelectedItems.isEmpty)
            #expect(state.selectedChildrenCount?.selectedChildrenCount == 0)
        }

        var expectedSelected: Set<String> = [parentId]
        expectedSelected.formUnion(descendantIds)
        
        await store.send(.toggleSelection)
        await store.receive(\.selectedChildrenCount.countSelectedChildren) {
            $0.selectedChildrenCount?.selectedChildrenCount = expectedSelectedChildrenCount
        }

        store.assert { state in
            #expect(state.isSelected)
            #expect(state.allSelectedItems == expectedSelected)
            #expect(state.title == parentItem.displayName)
        }
    }

    @Test
    func testToggleSelection_whenIncludeChildrenEnabled_deselectsParentAndDescendants() async {
        let parentItem = rootItems.first { $0.id == "1" }!
        let parentId = parentItem.id

        let descendantIds = await fakeNestedRepository.allDescendantsIDs(parentId)
        let initialSelectedChildrenCount = descendantIds.count

        let initialSelectedItems = Set([parentId] + descendantIds)
        let sharedSelectedItems = makeSharedState(initialValue: initialSelectedItems)

        let initialState = NestedItemsPicker<String>.State(
            id: parentId,
            pickerModel: parentItem,
            includeChildrenEnabled: true,
            selectedChildrenCount: SelectedChildrenCount<String>.State(
                allSelectedItems: sharedSelectedItems,
                item: parentItem,
                selectedChildrenCount: initialSelectedChildrenCount // All children initially selected
            ),
            searchItems: nil,
            showSelectedChildrenCount: true,
            showSearchBar: false,
            title: parentItem.displayName,
            emptyStateReason: nil,
            allSelectedItems: sharedSelectedItems
        )

        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }

        store.exhaustivity = .off

        store.assert { state in
            #expect(state.isSelected, "Parent item '\(parentId)' should initially be selected.")
            #expect(state.allSelectedItems == initialSelectedItems, "allSelectedItems should initially contain parent and all descendants.")
            #expect(state.selectedChildrenCount?.selectedChildrenCount == initialSelectedChildrenCount, "selectedChildrenCount for item '\(parentId)' should initially be \(initialSelectedChildrenCount).")
        }

        await store.send(.toggleSelection)

        await store.receive(\.selectedChildrenCount.countSelectedChildren) {
            $0.selectedChildrenCount?.selectedChildrenCount = 0
        }

        store.assert { state in
            #expect(!state.isSelected, "Parent item '\(parentId)' should be deselected.")
            #expect(state.allSelectedItems.isEmpty, "allSelectedItems should be empty. Got: \(state.allSelectedItems)")
            #expect(state.selectedChildrenCount?.selectedChildrenCount == 0, "selectedChildrenCount for item '\(parentId)' should be 0. Got \(state.selectedChildrenCount?.selectedChildrenCount ?? -1)")
        }
    }



    @Test
    func testSearchItems_setSearchResultsUpdatesNestedState() async {
        let sharedSelectedItems = makeSharedState(initialValue: [])

        let initialState = NestedItemsPicker<String>.State(
            id: "root",
            pickerModel: nil,
            includeChildrenEnabled: true,
            selectedChildrenCount: nil,
            searchItems: SearchItems<String>.State(),
            showSelectedChildrenCount: false,
            showSearchBar: true,
            title: "All items",
            emptyStateReason: nil,
            allSelectedItems: sharedSelectedItems
        )

        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }

        let query = "1.1.1"
        let results = await fakeNestedRepository.searchItems(query)
        await store.send(.searchItems(.searchQueryChanged(query))) {
            $0.searchItems?.searchQuery = query
        }

        await store.send(.searchItems(.searchQueryDebounced))

        await store.receive(\.searchItems.setSearchResults) { state in
            state.searchItems?.searchResults = results
            state.emptyStateReason = nil
            state.nested = IdentifiedArrayOf(
                uniqueElements: results.map { itemModel in
                    makeExpectedNestedState(item: itemModel, parentState: initialState)
                }
            )
        }
    }

    @Test
    func testSearchItems_clearSearchWithEmptyQueryRefetchesChildren() async {
        let initialQuery = "1.1.1"
        let searchResults = await fakeNestedRepository.searchItems(initialQuery)
        let initialSearchResults = IdentifiedArrayOf(uniqueElements: searchResults)

        let sharedSelectedItems = makeSharedState()

        var initialState = NestedItemsPicker<String>.State(
            id: "root",
            pickerModel: nil,
            includeChildrenEnabled: false,
            selectedChildrenCount: nil,
            searchItems: SearchItems<String>.State(
                searchQuery: initialQuery, // Start with a non-empty query
                searchResults: initialSearchResults // And corresponding results
            ),
            showSelectedChildrenCount: false,
            showSearchBar: true,
            title: "Root Item",
            emptyStateReason: nil,
            allSelectedItems: sharedSelectedItems
        )

        let nestedState = searchResults.map { itemModel in
            makeExpectedNestedState(item: itemModel, parentState: initialState)
        }
        initialState.nested = IdentifiedArray(uniqueElements: nestedState)

        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }
        store.exhaustivity = .off

        await store.send(.searchItems(.clearSearchQuery)) {
            $0.searchItems?.searchQuery = ""
            $0.searchItems?.searchResults = []
        }

        await store.receive(\.searchItems.delegate.searchCleared, timeout: .seconds(1)) {
            $0.nested = []
        }

        await store.receive(\.setItems.success, timeout: .seconds(1))
    }


    // MARK: - Empty States

    @Test
    func testSearch_noResults_setsEmptyState() async {
        let sharedSelectedItems = makeSharedState(initialValue: [])

        let initialState = NestedItemsPicker<String>.State(
            id: "root",
            pickerModel: nil,
            includeChildrenEnabled: true,
            selectedChildrenCount: nil,
            searchItems: SearchItems<String>.State(),
            showSelectedChildrenCount: false,
            showSearchBar: true,
            title: "All items",
            emptyStateReason: nil,
            allSelectedItems: sharedSelectedItems
        )

        let store = TestStore(initialState: initialState) {
            NestedItemsPicker<String>(repository: fakeNestedRepository)
        }

        let query = "no results query"
        await store.send(.searchItems(.searchQueryChanged(query))) {
            $0.searchItems?.searchQuery = query
        }

        await store.send(.searchItems(.searchQueryDebounced))

        await store.receive(\.searchItems.setSearchResults) { state in
            state.searchItems?.searchResults = []
            state.emptyStateReason = .searchResultEmpty
            state.nested = []
        }
    }
}

// Add DependencyKey for NestedItemsRepository if not already present
extension DependencyValues {
    var nestedItemsRepository: NestedItemsRepository<String> { // Use concrete type for tests
        get { self[NestedItemsRepositoryKey.self] }
        set { self[NestedItemsRepositoryKey.self] = newValue }
    }
}

// Define the DependencyKey
private struct NestedItemsRepositoryKey: TestDependencyKey {
    // Provide a default value (e.g., the mock repository) for tests
    static let testValue = itemsRepository // Assuming 'itemsRepository' is the mock defined in NestedItemsRepository.swift
    // static let previewValue = itemsRepository // Add preview value if needed
}
