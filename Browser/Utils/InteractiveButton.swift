// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct InteractiveButton<Content>: View where Content: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Content

    @State private var pressed: Bool = false

    var body: some View {
        Button {
            action()
        } label: {
            label()
                .scaleEffect(pressed ? 0.95 : 1)
                .animation(.default, value: pressed)
        }
        .buttonStyle(.reportsPresses(pressed: $pressed))
    }
}
