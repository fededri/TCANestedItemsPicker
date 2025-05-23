//
//  ContentView.swift
//  TCANestedItemsPickerExample
//
//  Created by Federico Torres on 20/05/25.
//

import SwiftUI
import TCANestedItemsPicker

struct EmptyStateView: View {
    let reason: NestedItemsPicker<String>.EmptyStateReason
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: imageForReason)
                .font(.system(size: 70))
                .foregroundColor(.gray)
                .padding()
            
            Text(titleForReason)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(messageForReason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var imageForReason: String {
        switch reason {
        case .noChildrenFound:
            return "tray.fill"
        case .searchResultEmpty:
            return "magnifyingglass"
        case .errorLoadingChildren, .errorSearchingItems:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var titleForReason: String {
        switch reason {
        case .noChildrenFound:
            return "No Items Found"
        case .searchResultEmpty:
            return "No Search Results"
        case .errorLoadingChildren:
            return "Error Loading Items"
        case .errorSearchingItems:
            return "Search Error"
        }
    }
    
    private var messageForReason: String {
        switch reason {
        case .noChildrenFound:
            return "There are no items in this category."
        case .searchResultEmpty:
            return "Try a different search term or check for typos."
        case .errorLoadingChildren:
            return "There was an error loading items. Please try again later."
        case .errorSearchingItems:
            return "There was an error performing your search. Please try again."
        }
    }
}

// MARK: - Previews
#Preview("No Children") {
    EmptyStateView(reason: .noChildrenFound)
}

#Preview("Search Empty") {
    EmptyStateView(reason: .searchResultEmpty)
}

#Preview("Error Loading") {
    EmptyStateView(reason: .errorLoadingChildren)
}

#Preview("Search Error") {
    EmptyStateView(reason: .errorSearchingItems)
} 
