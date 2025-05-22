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
        public var isLoading = false
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

    @CasePathable
    public enum DelegateAction: Equatable {
        case searchCleared
        case searchFailed
        case searchLoadingStarted
        case searchLoadingFinished
    }

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
                    return .concatenate(
                        .cancel(id: CancelID.searchRequest),
                        .send(.delegate(.searchCleared))
                    )
                }
                return .none
            case .binding:
                return .none

            case .clearSearchQuery:
                guard !state.searchQuery.isEmpty else { return .none }
                state.searchQuery = ""
                state.searchResults = []
                return .concatenate(
                    .cancel(id: CancelID.searchRequest),
                    .send(.delegate(.searchCleared))
                )

            case .searchQueryDebounced:
                guard !state.searchQuery.isEmpty else {
                    state.searchResults = []
                    return .cancel(id: CancelID.searchRequest)
                }

                state.isLoading = true
                
                return .concatenate(
                    .send(.delegate(.searchLoadingStarted)),
                    .run { [query = state.searchQuery] send in
                        await send(.setSearchResults(
                            Result(catching: {
                                await nestedItemsRepository.searchItems(query)
                            })
                        ))
                    }
                    .cancellable(id: CancelID.searchRequest, cancelInFlight: true)
                )

            case .setSearchResults(.success(let items)):
                state.isLoading = false
                
                guard !state.searchQuery.isEmpty else {
                   return .send(.delegate(.searchLoadingFinished))
                }
                state.searchResults = items
                return .send(.delegate(.searchLoadingFinished))

            case .setSearchResults(.failure):
                state.isLoading = false
                
                guard !state.searchQuery.isEmpty else {
                   return .send(.delegate(.searchLoadingFinished))
                }
                state.searchResults = []
                return .concatenate(
                    .send(.delegate(.searchFailed)),
                    .send(.delegate(.searchLoadingFinished))
                )

            case .delegate:
                return .none
            }
        }
    }
}

