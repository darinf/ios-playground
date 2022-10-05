//
//  InteractiveCardView.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/4/22.
//

import SwiftUI

fileprivate struct InteractiveButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) {
                isPressed = $0
            }
    }
}

struct InteractiveButtonView<Label>: View where Label: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            action()
        } label: {
            label()
        }
        .buttonStyle(InteractiveButtonStyle(isPressed: $isPressed))
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.easeOut, value: isPressed)
    }
}
