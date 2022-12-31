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
        GeometryReader { geom in
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
            }
            .buttonStyle(.reportsPresses(pressed: $model.pressed))
            .highPriorityGesture(
                DragGesture(coordinateSpace: .named("grid"))
                    .onChanged {
                        print(">>> Drag onChanged: \($0.translation)")
                        let currentOrigin = geom.frame(in: .named("grid")).origin
//                        let offset = currentOrigin - model.dragOrigin
                        let adjustedTranslation: CGSize = .init(
                            width: model.dragOrigin.x - currentOrigin.x + $0.translation.width,
                            height: model.dragOrigin.y - currentOrigin.y + $0.translation.height)
                        model.dragTranslation = adjustedTranslation
                        if let direction = translationToDirection($0.translation) {
                            handler(.move(direction))
                        }
                    }
                    .onEnded { _ in
                        print(">>> Drag onEnded, card.title: \(model.card.title)")
                        model.longPressed = false
                    }
                    .simultaneously(with: LongPressGesture()
                        .onEnded { _ in
                            model.dragTranslation = .zero
                            model.dragOrigin = geom.frame(in: .named("grid")).origin
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
//                            .animation(nil)
                    }
                }
            )
        }
        .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        .zIndex(zIndex)
    }

    func translationToDirection(_ translation: CGSize) -> CardView<Card>.Direction? {
        let threshold: CGFloat = 50
        if abs(translation.width) > abs(translation.height) {
            if abs(translation.width) > threshold {
                return translation.width > 0 ? .right : .left
            }
        } else {
            if abs(translation.height) > threshold {
                return translation.height > 0 ? .down : .up
            }
        }
        return nil
    }
}

