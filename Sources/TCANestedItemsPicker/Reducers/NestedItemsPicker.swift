//
//  NestedItemsPicker.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct NestedItemsPicker<ID: Hashable & Sendable>: Reducer, Sendable {
    private let nestedItemsRepository: NestedItemsRepository<ID>

    public init(repository: NestedItemsRepository<ID>) {
        self.nestedItemsRepository = repository
    }

    @ObservableState
    public struct State: Equatable, Identifiable {
        public let id: ID
        public var nested: IdentifiedArrayOf<State> = []
        public var pickerModel: PickerItemModel<ID>?
        public var includeChildrenEnabled = false
        public var selectedChildrenCount: SelectedChildrenCount<ID>.State?
        public var searchItems: SearchItems<ID>.State?
        public let showSelectedChildrenCount: Bool
        public var showSearchBar = true
        public var title = ""
        public var emptyStateReason: EmptyStateReason?
        public var isLoading = false

        @ObservationStateIgnored
        @Shared var allSelectedItems: Set<ID>

        public var isSelected: Bool {
            return allSelectedItems.contains(id)
        }

        public init(
            id: ID,
            pickerModel: PickerItemModel<ID>? = nil,
            includeChildrenEnabled: Bool = false,
            showSelectedChildrenCount: Bool,
            showSearchBar: Bool = true,
            title: String = "",
            allSelectedItems: Shared<Set<ID>> = Shared(value: []),
        ) {
            self.id = id
            self.pickerModel = pickerModel
            self.includeChildrenEnabled = includeChildrenEnabled
            self.showSelectedChildrenCount = showSelectedChildrenCount
            self.showSearchBar = showSearchBar
            self.title = title.isEmpty && pickerModel != nil ? pickerModel!.displayName : title
            self._allSelectedItems = allSelectedItems
            self.nested = []

            self.selectedChildrenCount = showSelectedChildrenCount && pickerModel != nil ? SelectedChildrenCount<ID>.State(allSelectedItems: allSelectedItems, item: pickerModel!) : nil
        }

        public init(
            id: ID,
            initialItems: IdentifiedArrayOf<PickerItemModel<ID>>,
            includeChildrenEnabled: Bool = false,
            showSelectedChildrenCount: Bool,
            showSearchBar: Bool = true,
            title: String,
            allSelectedItems: Shared<Set<ID>>
        ) {
            self.id = id
            self.pickerModel = nil
            self.includeChildrenEnabled = includeChildrenEnabled
            self.showSelectedChildrenCount = showSelectedChildrenCount
            self.selectedChildrenCount = nil
            self.showSearchBar = showSearchBar
            self.title = title
            self._allSelectedItems = allSelectedItems

            self.nested = mapItemsToNestedState(
                initialItems,
                parentIncludeChildrenEnabled: includeChildrenEnabled,
                showSelectedChildrenCount: showSelectedChildrenCount,
                showSearchBar: showSearchBar,
                allSelectedItems: allSelectedItems
            )
        }

    #if DEBUG
        init(
            id: ID,
            nested: IdentifiedArrayOf<State> = [],
            pickerModel: PickerItemModel<ID>? = nil,
            includeChildrenEnabled: Bool = false,
            selectedChildrenCount: SelectedChildrenCount<ID>.State? = nil,
            searchItems: SearchItems<ID>.State? = nil,
            showSelectedChildrenCount: Bool = false,
            showSearchBar: Bool = true,
            title: String = "",
            emptyStateReason: EmptyStateReason? = nil,
            isLoading: Bool = false,
            allSelectedItems: Shared<Set<ID>>
        ) {
            self.id = id
            self.nested = nested
            self.pickerModel = pickerModel
            self.includeChildrenEnabled = includeChildrenEnabled
            self.selectedChildrenCount = selectedChildrenCount
            self.searchItems = searchItems
            self.showSelectedChildrenCount = showSelectedChildrenCount
            self.showSearchBar = showSearchBar
            self.title = title.isEmpty && pickerModel != nil ? pickerModel!.displayName : title
            self.emptyStateReason = emptyStateReason
            self.isLoading = isLoading
            self._allSelectedItems = allSelectedItems
        }
    #endif
    }

    public enum EmptyStateReason {
        case noChildrenFound
        case searchResultEmpty
        case errorLoadingChildren
        case errorSearchingItems
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case selectedChildrenCount(SelectedChildrenCount<ID>.Action)
        case searchItems(SearchItems<ID>.Action)
        indirect case nested(IdentifiedActionOf<NestedItemsPicker<ID>>)
        case toggleSelection
        case addSelectedItems([ID])
        case removeSelectedItems([ID])
        case onFirstAppear

        case setItems(Result<IdentifiedArrayOf<PickerItemModel<ID>>, Error>)
        case setIncludeChildrenEnabled(Bool)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .setIncludeChildrenEnabled(let enabled):
                guard state.includeChildrenEnabled != enabled else {
                    return .none
                }
                state.includeChildrenEnabled = enabled

                return .run { [nestedIds = state.nested.ids] send in
                    for id in nestedIds {
                        await send(.nested(.element(id: id, action: .setIncludeChildrenEnabled(enabled))))
                    }
                }
            case .onFirstAppear:
                guard state.nested.isEmpty else { return .none }

                if state.showSearchBar {
                    state.searchItems = SearchItems.State()
                }
                
                state.isLoading = true
                
                return .run { [parentId = state.id] send in
                    await send(.setItems(
                        Result(catching: {
                            try await nestedItemsRepository.childrenItemsByParentId(parentId)
                        })
                    ))
                }
            case .setItems(.success(let items)):
                state.isLoading = false
                
                guard !items.isEmpty else {
                    state.emptyStateReason = .noChildrenFound
                    state.nested = []
                    return .none
                }
                state.emptyStateReason = nil
                state.nested = self.mapItemsToState(items, state: state)
                return .none
            case .setItems(.failure):
                state.isLoading = false
                
                state.nested = []
                state.emptyStateReason = .errorLoadingChildren
                return .none
            case .nested(.element(_, let action)):
                if action.containsToggleSelection,
                   state.includeChildrenEnabled {
                    return .send(.selectedChildrenCount(.computeSelectedChildrenCount))
                }
                return .none

            case .nested:
                return .none
            case .toggleSelection:
                state.$allSelectedItems.withLock {
                    $0.insertOrRemove(state.id)
                }
                return self.handleToggleSelection(state: &state)
            case .addSelectedItems(let ids):
                state.$allSelectedItems.withLock { $0 = $0.union(ids) }
                return .run { [computeSelectedChildren = state.showSelectedChildrenCount] send in
                    if computeSelectedChildren {
                        await send(.selectedChildrenCount(.computeSelectedChildrenCount))
                    }
                }
            case .removeSelectedItems(let ids):
                state.$allSelectedItems.withLock {
                    $0 = $0.subtracting(ids)
                }
                return .run { [computeSelectedChildren = state.showSelectedChildrenCount] send in
                    if computeSelectedChildren {
                        await send(.selectedChildrenCount(.computeSelectedChildrenCount))
                    }
                }
            case .selectedChildrenCount:
                return .none
            case .searchItems(.delegate(.searchLoadingStarted)):
                state.isLoading = true
                return .none
                
            case .searchItems(.delegate(.searchLoadingFinished)):
                state.isLoading = false
                return .none
                
            case .searchItems(.setSearchResults(.success(let items))):
                guard !items.isEmpty else {
                    state.emptyStateReason = .searchResultEmpty
                    return .none
                }
                state.emptyStateReason = nil
                state.nested = self.mapItemsToState(items, state: state)
                return .none
            case .searchItems(.delegate(.searchCleared)):
                guard state.searchItems?.searchQuery.isEmpty ?? true else { return .none }

                state.nested = []
                state.emptyStateReason = nil
                
                state.isLoading = true
                
                return .run { [parentId = state.id] send in
                    await send(.setItems(
                        Result(catching: {
                            try await nestedItemsRepository.childrenItemsByParentId(parentId)
                        })
                    ))
                }
            case .searchItems(.delegate(.searchFailed)):
                state.emptyStateReason = .errorSearchingItems
                state.nested = []
                return .none
            case .searchItems:
                return .none
            }
        }
        .ifLet(\.selectedChildrenCount, action: \.selectedChildrenCount) {
            SelectedChildrenCount<ID>(repository: nestedItemsRepository)
        }
        .ifLet(\.searchItems, action: \.searchItems) {
            SearchItems(repository: nestedItemsRepository)
        }
        .forEach(\.nested, action: \.nested) {
            Self(repository: nestedItemsRepository)
        }
    }

    private func handleToggleSelection(state: inout State) -> Effect<Action> {
        var effects: [Effect<Action>] = []

        if state.includeChildrenEnabled {
            let currentId = state.id
            let isSelected = state.isSelected

            effects.append(.run { send in
                let childrenIds = await nestedItemsRepository.allDescendantsIDs(currentId)
                if isSelected {
                    await send(.addSelectedItems(childrenIds))
                } else {
                    await send(.removeSelectedItems(childrenIds))
                }
            })
        }

        return .concatenate(effects)
    }

    /// Maps an array of `PickerItemModel` to an array of `NestedItemsPicker.State`.
    /// Static version for use in initializer and reducer.
    private static func mapItemsToNestedState(
        _ items: IdentifiedArrayOf<PickerItemModel<ID>>,
        parentIncludeChildrenEnabled: Bool,
        showSelectedChildrenCount: Bool,
        showSearchBar: Bool,
        allSelectedItems: Shared<Set<ID>>
    ) -> IdentifiedArrayOf<State> {
        let newElements = items.map { model -> State in
            State(
                id: model.id,
                pickerModel: model,
                includeChildrenEnabled: parentIncludeChildrenEnabled,
                showSelectedChildrenCount: showSelectedChildrenCount,
                showSearchBar: showSearchBar,
                title: model.displayName,
                allSelectedItems: allSelectedItems
            )
        }
        return IdentifiedArray(uniqueElements: newElements)
    }

    private func mapItemsToState(
        _ items: IdentifiedArrayOf<PickerItemModel<ID>>,
        state: State
    ) -> IdentifiedArrayOf<State> {
        return Self.mapItemsToNestedState(
            items,
            parentIncludeChildrenEnabled: state.includeChildrenEnabled,
            showSelectedChildrenCount: state.showSelectedChildrenCount,
            showSearchBar: state.showSearchBar,
            allSelectedItems: state.$allSelectedItems
        )
    }
}

fileprivate extension Set {
    mutating func insertOrRemove(_ element: Element) {
        if self.contains(element) {
            self.remove(element)
        } else {
            self.insert(element)
        }
    }
}

fileprivate extension NestedItemsPicker.Action {
    var containsToggleSelection: Bool {
        switch self {
        case .toggleSelection:
            return true
        case .nested(.element(_, let nestedAction)):
            return nestedAction.containsToggleSelection
        default:
            return false
        }
    }
}
