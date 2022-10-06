// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ReportsPressesButtonStyle: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) {
                pressed = $0
            }
    }
}

extension ButtonStyle where Self == ReportsPressesButtonStyle {
    static func reportsPresses(pressed: Binding<Bool>) -> Self {
        .init(pressed: pressed)
    }
}
