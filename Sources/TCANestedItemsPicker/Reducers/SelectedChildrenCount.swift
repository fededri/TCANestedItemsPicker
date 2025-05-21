//
//  SelectedChildrenCount.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct SelectedChildrenCount<ID: Hashable & Sendable>: Reducer, Sendable {

    private let repository: NestedItemsRepository<ID>

    public init(repository: NestedItemsRepository<ID>) {
        self.repository = repository
    }

    @ObservableState
    public struct State: Equatable {
        @ObservationStateIgnored
        @Shared var allSelectedItems: Set<ID>
        public let item: PickerItemModel<ID>
        public var selectedChildrenCount: Int = 0

        public init(allSelectedItems: Shared<Set<ID>>, item: PickerItemModel<ID>) {
            self._allSelectedItems = allSelectedItems
            self.item = item
        }

        public var countDisplayText: String {
            if selectedChildrenCount > 0 {
                "\(selectedChildrenCount) included"
            } else {
                ""
            }
        }
    }

    @CasePathable
    public enum Action {
        case computeSelectedChildrenCount
        case countSelectedChildren([ID])
    }

    enum CancelID { case computeSelectedChildren }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .computeSelectedChildrenCount:
                if state.item.hasChildren {
                    return .cancellable(id: CancelID.computeSelectedChildren, { [item = state.item] send in
                        let allDescendants = await repository.allDescendantsIDs(item.id)
                        await send(.countSelectedChildren(allDescendants))
                    })
                } else {
                    return .none
                }
            case .countSelectedChildren(let descendantIds):
                var count = 0
                if !descendantIds.isEmpty {
                    count = descendantIds.filter({ state.allSelectedItems.contains($0)
                    }).count
                }
                state.selectedChildrenCount = count
                return .none
            }
        }
    }
}


struct SelectedChildrenCountTextView<ID: Hashable & Sendable>: View {
    @Perception.Bindable var store: StoreOf<SelectedChildrenCount<ID>>

    var body: some View {
        WithPerceptionTracking {
            Text(store.countDisplayText)
                .onFirstAppear {
                    store.send(.computeSelectedChildrenCount)
                }
        }
    }
}

extension Effect {
    static func cancellable<ID: Hashable & Sendable>(
        id: ID,
        _ operation: @escaping @Sendable (_ send: Send<Action>) async throws -> Void
    ) -> Self {
        .run(operation: operation)
        .cancellable(id: id, cancelInFlight: true)
    }
}
