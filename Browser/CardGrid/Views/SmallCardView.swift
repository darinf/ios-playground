// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    enum Action { case activated, closed }

    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let handler: (_ action: Action) -> Void

    var body: some View {
        Button() {
            handler(.activated)
        } label: {
            Group {
                if selected && zoomed {
                    Color.clear
                } else {
                    CardView(namespace: namespace, model: model, selected: selected, zoomed: false) {
                        switch $0 {
                        case .closed:
                            handler(.closed)
                        }
                    }
                }
            }
            .transition(.identity.animation(.default))
            .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        }
        .buttonStyle(.reportsPresses(pressed: $model.pressed))
        .zIndex(selected ? 1 : 0)
    }
}

