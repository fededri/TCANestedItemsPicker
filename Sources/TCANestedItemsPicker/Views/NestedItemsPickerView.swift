//
//  NestedItemsPickerView.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 19/05/25.
//

import ComposableArchitecture
import SwiftUI

struct NestedItemsPickerView<ID: Hashable & Sendable, EmptyStateContent: View>: View {
    @ComposableArchitecture.Bindable var store: StoreOf<NestedItemsPicker<ID>>
    let emptyStateContent: (NestedItemsPicker<ID>.EmptyStateReason) -> EmptyStateContent

    init(
        store: StoreOf<NestedItemsPicker<ID>>,
        @ViewBuilder emptyStateContent: @escaping (NestedItemsPicker<ID>.EmptyStateReason) -> EmptyStateContent
    ) {
        self.store = store
        self.emptyStateContent = emptyStateContent
    }

    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                Form {
                    if let searchStore = store.scope(state: \.searchItems, action: \.searchItems) {
                        searchBar(store: searchStore)
                    }

                    Toggle(
                        "Include Children",
                        isOn: $store.includeChildrenEnabled.sending(
                            \.setIncludeChildrenEnabled)
                    )

                    if let emptyStateReason = store.emptyStateReason {
                        emptyStateContent(emptyStateReason)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.scope(state: \.nested, action: \.nested)) {
                            rowStore in
                            WithPerceptionTracking {
                                nestedItemRowView(store: rowStore, emptyStateContent: emptyStateContent)
                            }
                        }
                    }
                }
                .onFirstAppear {
                    store.send(.onFirstAppear)
                }
                .navigationTitle(store.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder
    private func nestedItemRowView(
        store: StoreOf<NestedItemsPicker<ID>>,
        @ViewBuilder emptyStateContent: @escaping (NestedItemsPicker<ID>.EmptyStateReason) -> EmptyStateContent
    ) -> some View {
        if store.pickerModel?.hasChildren == true {
            NavigationLink {
                NestedItemsPickerView(store: store, emptyStateContent: emptyStateContent)
            } label: {
                NestedItemRowView(store: store)
            }
        } else {
            NestedItemRowView(store: store)
        }
    }

    @ViewBuilder
    private func searchBar(store: StoreOf<SearchItems<ID>>) -> some View {
        @ComposableArchitecture.Bindable var searchStore = store
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(
                "Search Items...",
                text: $searchStore.searchQuery.sending(\.searchQueryChanged)
            )
            .autocapitalization(.none)
            .disableAutocorrection(true)

            if !searchStore.searchQuery.isEmpty {
                Button {
                    store.send(.clearSearchQuery)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(UIColor.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .task(id: store.searchQuery) {
            do {
                try await Task.sleep(for: .milliseconds(300))
                await store.send(.searchQueryDebounced).finish()
            } catch {}
        }
    }
}
