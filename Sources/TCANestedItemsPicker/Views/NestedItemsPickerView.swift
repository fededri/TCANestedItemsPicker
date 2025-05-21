//
//  NestedItemsPickerView.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 19/05/25.
//

import ComposableArchitecture
import SwiftUI

public struct NestedItemsPickerView<ID: Hashable & Sendable, EmptyStateContent: View>: View {
    @ComposableArchitecture.Bindable var store: StoreOf<NestedItemsPicker<ID>>
    let emptyStateContent: (NestedItemsPicker<ID>.EmptyStateReason) -> EmptyStateContent

    public init(
        store: StoreOf<NestedItemsPicker<ID>>,
        @ViewBuilder emptyStateContent: @escaping (NestedItemsPicker<ID>.EmptyStateReason) -> EmptyStateContent
    ) {
        self.store = store
        self.emptyStateContent = emptyStateContent
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    formContent
                        .navigationTitle(store.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .onFirstAppear {
                            store.send(.onFirstAppear)
                        }
                    
                    if store.isLoading {
                        loadingOverlay
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var formContent: some View {
        Form {
            if let searchStore = store.scope(state: \.searchItems, action: \.searchItems) {
                searchBar(store: searchStore)
            }

            Toggle(
                "Include Children",
                isOn: $store.includeChildrenEnabled.sending(
                    \.setIncludeChildrenEnabled)
            )

            if store.isLoading {
                VStack {
                    Spacer().frame(height: 50)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else if let emptyStateReason = store.emptyStateReason {
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
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        VStack {
            loadingView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
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
        VStack {
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
}
