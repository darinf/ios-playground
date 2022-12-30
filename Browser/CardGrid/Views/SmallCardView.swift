// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let handler: (_ action: CardView<Card>.Action) -> Void
    @State var longPressed = false

    var body: some View {
        Button {
            if longPressed {
                longPressed = false
            } else {
                handler(.activated)
            }
        } label: {
            Group {
                if selected && zoomed || longPressed {
                    Color.clear
                } else {
                    CardView(namespace: namespace, model: model, selected: selected, zoomed: false, handler: handler)
                }
            }
            .transition(.identity.animation(.default))
            .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        }
        .buttonStyle(.reportsPresses(pressed: $model.pressed))
        .zIndex(selected ? 1 : 0)
        .highPriorityGesture(
            DragGesture()
                .onChanged {
                    print(">>> Drag onChanged: \($0.translation)")
                }
                .onEnded { _ in
                    longPressed = false
                }
                .simultaneously(with: LongPressGesture()
                    .onEnded { _ in
                        longPressed = true
                    }
                    .sequenced(before: TapGesture()
                        .onEnded {
                            longPressed = false
                        }
                    )
                )
        )
        .highPriorityGesture(TapGesture()
            .onEnded {
                longPressed = false
                handler(.activated)
            }
        )
    }
}

