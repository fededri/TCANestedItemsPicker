//
//  File.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct SearchItems<ID: Hashable & Sendable>: Reducer, Sendable {
    public typealias PickerModel = PickerItemModel<ID>
    private let nestedItemsRepository: NestedItemsRepository<ID>

    public init(repository: NestedItemsRepository<ID>) {
        self.nestedItemsRepository = repository
    }

    @ObservableState
    public struct State: Equatable {
        public var searchQuery = ""
        public var searchResults: IdentifiedArrayOf<PickerModel> = []
        
        public init(searchQuery: String = "") {
            self.searchQuery = searchQuery
        }
    }

    @CasePathable
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchQueryChanged(String)
        case searchQueryDebounced
        case setSearchResults(Result<IdentifiedArrayOf<PickerModel>, Error>)
        case delegate(DelegateAction)
        case clearSearchQuery
    }

    // actions the parent should handle
    @CasePathable
    public enum DelegateAction: Equatable {
        case searchCleared
        case searchFailed
    }

    // Re-introduce CancelID for the network request
    enum CancelID { case searchRequest }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .searchQueryChanged(let searchQuery):
                guard searchQuery != state.searchQuery else {
                    return .none
                }
                state.searchQuery = searchQuery

                if state.searchQuery.isEmpty {
                    state.searchResults = []
                    // Send delegate action AND cancel
                    return .concatenate(
                        .cancel(id: CancelID.searchRequest),
                        .send(.delegate(.searchCleared))
                    )
                }
                return .none
            case .binding:
                return .none

            case .clearSearchQuery:
                // Check if already empty to avoid redundant work
                guard !state.searchQuery.isEmpty else { return .none }
                state.searchQuery = ""
                state.searchResults = []
                // Send delegate action AND cancel
                return .concatenate(
                    .cancel(id: CancelID.searchRequest),
                    .send(.delegate(.searchCleared))
                )

            case .searchQueryDebounced:
                guard !state.searchQuery.isEmpty else {
                    state.searchResults = []
                    return .cancel(id: CancelID.searchRequest)
                }

                // Perform the actual search, making it cancellable
                return .run { [query = state.searchQuery] send in
                    await send(.setSearchResults(
                        Result(catching: {
                            await nestedItemsRepository.searchItems(query)
                        })
                    ))
                }
                .cancellable(id: CancelID.searchRequest, cancelInFlight: true)

            case .setSearchResults(.success(let items)):
                // Only update if the search query hasn't become empty since the request started
                guard !state.searchQuery.isEmpty else {
                   return .none
                }
                state.searchResults = items
                return .none

            case .setSearchResults(.failure):
                 // Only process failure if query is still active
                guard !state.searchQuery.isEmpty else {
                   return .none
                }
                state.searchResults = []
                // Send delegate action on failure
                return .send(.delegate(.searchFailed))

            case .delegate:
                return .none
            }
        }
    }
}

