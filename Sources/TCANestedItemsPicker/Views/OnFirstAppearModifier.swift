//
//  OnFirstAppearModifier.swift
//  TCANestedItemsPicker
//
//  Created by Federico Torres on 19/05/25.
//

import SwiftUI

struct OnFirstAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    action()
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        self.modifier(OnFirstAppearModifier(action: action))
    }
}
