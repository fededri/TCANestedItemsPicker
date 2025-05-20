//
//  File.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 16/05/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct SelectedChildrenCount<ID: Hashable & Sendable>: Reducer {

    private let repository: NestedItemsRepository<ID>

    init(repository: NestedItemsRepository<ID>) {
        self.repository = repository
    }

    @ObservableState
    struct State: Equatable {
        @ObservationStateIgnored
        @Shared var allSelectedItems: Set<ID>
        let item: PickerItemModel<ID>
        var selectedChildrenCount: Int = 0


        var countDisplayText: String {
            if selectedChildrenCount > 0 {
                "\(selectedChildrenCount) included"
            } else {
                ""
            }
        }
    }

    @CasePathable
    enum Action {
        case computeSelectedChildrenCount
        case countSelectedChildren([ID])
    }

    enum CancelID { case computeSelectedChildren }

    var body: some ReducerOf<Self> {
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
                    print("calculated: calculating count")
                    count = descendantIds.filter({ state.allSelectedItems.contains($0)
                    }).count
                } else {
                    print("skipping calculation")
                }

                print("Calculated count for item id: \(state.item.id): \(count)")
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
