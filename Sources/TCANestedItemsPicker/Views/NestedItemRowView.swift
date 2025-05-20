//
//  NestedItemRowView.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 19/05/25.
//

import ComposableArchitecture
import SwiftUI

struct NestedItemRowView<ID: Hashable & Sendable>: View {

    @ComposableArchitecture.Bindable var store: StoreOf<NestedItemsPicker<ID>>

    var body: some View {
        WithPerceptionTracking {
            HStack(spacing: 0) {
                Button {
                    store.send(.toggleSelection)
                } label: {
                    Image(systemName: store.isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(store.isSelected ? .blue : .gray)
                        .contentShape(Rectangle())
                        .padding(.trailing, 8)
                        .padding(.vertical, 8)
                }
                .buttonStyle(BorderlessButtonStyle())

                HStack {
                    Text(store.pickerModel?.displayName ?? "")
                        .foregroundColor(.primary)

                    Spacer()

                    if let countStore = store.scope(state: \.selectedChildrenCount, action: \.selectedChildrenCount) {
                        SelectedChildrenCountTextView(store: countStore)
                    }
                }
                .contentShape(Rectangle())
                .padding(.vertical, 8)
            }
        }
    }
}
