// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

// Adds behaviors to `CardView` when it lives in the grid.
struct SmallCardView<Card>: View where Card: CardModel {
    enum Direction { case up, down, left, right }
    enum Action { case activate, close, move(Direction), press(CGRect), pressEnded }

    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let handler: (_ action: Action) -> Void

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
            let hideCard = selected && zoomed || model.longPressed
            Button {
                if model.longPressed {
                    longPressEnded()
                } else {
                    handler(.activate)
                }
            } label: {
                Group {
                    if hideCard {
                        Color.clear
                    } else {
                        CardView(namespace: namespace, model: model, selected: selected, zoomed: false)
                    }
                }
                .transition(.identity.animation(.default))
            }
            .buttonStyle(.reportsPresses(pressed: $model.pressed))
            .highPriorityGesture(
                DragGesture(coordinateSpace: .named("grid"))
                    .onChanged {
                        if let direction = translationToDirection($0.translation, geom: geom) {
                            handler(.move(direction))
                        }
                    }
                    .onEnded { _ in
                        longPressEnded()
                    }
                    .simultaneously(with: LongPressGesture()
                        .onEnded { _ in
                            model.lastTranslation = .zero
                            model.translationOrigin = .zero
                            model.longPressed = true
                            handler(.press(geom.frame(in: .named("grid"))))
                        }
                        .sequenced(before: TapGesture()
                            .onEnded {
                                longPressEnded()
                            }
                        )
                    )
            )
            .highPriorityGesture(TapGesture()
                .onEnded {
                    longPressEnded()
                    handler(.activate)
                }
            )
            .overlay(
                Group {
                    if !hideCard {
                        CloseButtonView<Card>(namespace: namespace, model: model, handler: { handler(.close) })
                    }
                }
            )
        }
        .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        .zIndex(zIndex)
    }

    func longPressEnded() {
        if model.longPressed {
            model.longPressed = false
            handler(.pressEnded)
        }
    }

    // Assumes a translation relative to the current position of the card.
    func relativeTranslationToDirection(_ translation: CGSize, threshold: CGSize) -> Direction? {
        if abs(translation.width) > abs(translation.height) {
            if abs(translation.width) > threshold.width {
                return translation.width > 0 ? .right : .left
            }
        } else {
            if abs(translation.height) > threshold.height {
                return translation.height > 0 ? .down : .up
            }
        }
        return nil
    }

    // Given translation is in "grid" coordinate space. The card may already have been moved.
    func translationToDirection(_ translation: CGSize, geom: GeometryProxy) -> Direction? {
        let adjustedTranslation: CGSize = .init(
            width: translation.width - model.translationOrigin.width,
            height: translation.height - model.translationOrigin.height
        )
        // Remember the current translation so it can become the new translationOrigin
        // in case this move is accepted.
        model.lastTranslation = translation
        // It's important for threshold to be the size of the card so we avoid the
        // issue of moving from one cell to the next looking like we should move back.
        return relativeTranslationToDirection(adjustedTranslation, threshold: geom.size)
    }
}

