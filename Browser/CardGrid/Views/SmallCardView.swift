// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let handler: (_ action: CardView<Card>.Action) -> Void

    var zIndex: Double {
        if model.longPressed {
            return 2
        }
        if selected {
            return 1
        }
        return 0
    }

    var body: some View {
        Button {
            if model.longPressed {
                model.longPressed = false
            } else {
                handler(.activated)
            }
        } label: {
            Group {
                if selected && zoomed || model.longPressed {
                    Color.clear
                } else {
                    CardView(namespace: namespace, model: model, selected: selected, zoomed: false, handler: handler)
                }
            }
            .transition(.identity.animation(.default))
            .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        }
        .buttonStyle(.reportsPresses(pressed: $model.pressed))
        .zIndex(zIndex)
        .highPriorityGesture(
            DragGesture()
                .onChanged {
                    print(">>> Drag onChanged: \($0.translation)")
                    model.dragTranslation = $0.translation
                }
                .onEnded { _ in
                    model.longPressed = false
                }
                .simultaneously(with: LongPressGesture()
                    .onEnded { _ in
                        model.dragTranslation = .zero
                        model.longPressed = true
                    }
                    .sequenced(before: TapGesture()
                        .onEnded {
                            model.longPressed = false
                        }
                    )
                )
        )
        .highPriorityGesture(TapGesture()
            .onEnded {
                model.longPressed = false
                handler(.activated)
            }
        )
        .overlay(
            Group {
                if model.longPressed {
                    CardView(namespace: namespace, model: .init(card: model.card), selected: selected, zoomed: false)
                        .opacity(0.7)
                        .offset(x: model.dragTranslation.width, y: model.dragTranslation.height)
                }
            }
        )
    }
}

