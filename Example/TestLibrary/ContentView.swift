//
//  ContentView.swift
//  TestLibrary
//
//  Created by Federico Torres on 20/05/25.
//
import SwiftUI
import TCANestedItemsPicker
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        TabView {
            // Simple example
            PickerExampleView()
                .tabItem {
                    Label("Basic Example", systemImage: "list.bullet")
                }
            
            // TCA example with parent reducer
            TCAExampleView(
                store: Store(
                    initialState: NestedPickerExampleReducer.State(),
                    reducer: { NestedPickerExampleReducer() }
                )
            )
            .tabItem {
                Label("TCA Example", systemImage: "square.stack.3d.up")
            }
            
            // About view
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("TCA Nested Items Picker")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A powerful hierarchical item picker built with The Composable Architecture")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureItem(icon: "square.stack.3d.up", text: "Hierarchical navigation")
                FeatureItem(icon: "checkmark.circle", text: "Multi-select capability")
                FeatureItem(icon: "arrow.down.doc", text: "Include children option")
                FeatureItem(icon: "magnifyingglass", text: "Search functionality")
                FeatureItem(icon: "exclamationmark.triangle", text: "Empty states")
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Previews
#Preview("Content View") {
    ContentView()
}

#Preview("About View") {
    AboutView()
}

#Preview("Feature Item") {
    FeatureItem(icon: "star.fill", text: "Example Feature")
        .padding()
}
