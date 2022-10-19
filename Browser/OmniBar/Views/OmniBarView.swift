// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum OmniBarUX {
    static let shadowRadius: CGFloat = 2
    static let transitionAnimation = Animation.interactiveSpring()
    static let textColor = Color(uiColor: .label)
    static let buttonHeight: CGFloat = 40
    static let paddingBottom: CGFloat = 40
    static let dockedTopPadding: CGFloat = 12
    static let dockedHeight: CGFloat = buttonHeight + paddingBottom + dockedTopPadding
}

struct OmniBarView: View {
    enum Action {
        case urlField, newCard, showCards
    }

    @ObservedObject var model: OmniBarViewModel
    let namespace: Namespace.ID
    let zoomed: Bool
    let handler: (_ action: Action) -> Void

    // Raw Views

    @ViewBuilder
    var urlFieldView: some View {
        UrlFieldView(model: model.urlFieldViewModel, namespace: namespace, height: OmniBarUX.buttonHeight)
    }

    @ViewBuilder
    var newCardView: some View {
        NewCardView(namespace: namespace, height: OmniBarUX.buttonHeight)
    }

    @ViewBuilder
    var showCardsView: some View {
        ShowCardsView(namespace: namespace, height: OmniBarUX.buttonHeight)
    }

    @ViewBuilder
    var showMenuView: some View {
        ShowMenuView(namespace: namespace, height: OmniBarUX.buttonHeight)
    }

    @ViewBuilder
    func expandoView(height: CGFloat) -> some View {
        ExpandoView(namespace: namespace, height: height)
    }

    // Buttons

    @ViewBuilder
    var urlFieldButtonView: some View {
        Button {
            handler(.urlField)
        } label: {
            urlFieldView
        }
        .matchedGeometryEffect(id: "test", in: namespace)
        .zIndex(1)
        .opacity(model.canEditCurrentUrl ? 1 : 0)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var newCardButtonView: some View {
        Button {
            handler(.newCard)
        } label: {
            newCardView
        }
    }

    @ViewBuilder
    var showCardsButtonView: some View {
        Button {
            handler(.showCards)
        } label: {
            showCardsView
        }
    }

    @ViewBuilder
    var showMenuButtonView: some View {
        Group {
            // This is a workaround for Menu not animating offscreen correctly.
            // Only wrap with Menu when done animating to the non-hidden state.
            if model.hidden || !model.doneAnimatingHidden {
                showMenuView
            } else {
                Menu {
                    Toggle("Docked", isOn: $model.docked)
                } label: {
                    showMenuView
                }
                .menuStyle(.button)
            }
        }
    }

    @ViewBuilder
    var expandoButtonView: some View {
        InteractiveButton {
            withAnimation(OmniBarUX.transitionAnimation) {
                model.expanded.toggle()
            }
        } label: {
            expandoView(height: 40)
        }
    }

    // Layouts

    @ViewBuilder
    var expandedLayout: some View {
        VStack {
            HStack {
                Spacer()
                showMenuButtonView
            }
            HStack {
                urlFieldButtonView
                newCardButtonView
                showCardsButtonView
                expandoButtonView
            }
        }
        .padding([.leading, .trailing], 25)
    }

    @ViewBuilder
    var compactLayout: some View {
        HStack {
            Spacer()
            InteractiveButton {
                withAnimation(OmniBarUX.transitionAnimation) {
                    model.expanded.toggle()
                }
            } label: {
                ZStack {
                    urlFieldView
                        .frame(width: OmniBarUX.buttonHeight)
                    newCardView
                    showCardsView
                    showMenuView
                    expandoView(height: 50)
                }
            }
            .padding(.leading, 25)
            .padding(.trailing, 20)
        }
    }

    @ViewBuilder
    var dockedLayout: some View {
        HStack {
            urlFieldButtonView
            newCardButtonView
            showCardsButtonView
            ZStack {
                expandoView(height: 30)
                    .opacity(0)
                showMenuButtonView
            }
        }
        .padding([.leading, .trailing], 25)
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        VStack {
            Spacer()
            Group {
                if model.docked {
                    dockedLayout
                } else {
                    if model.expanded {
                        expandedLayout
                    } else {
                        compactLayout
                    }
                }
            }
            .padding(.bottom, OmniBarUX.paddingBottom)
            .padding(.top, model.docked ? OmniBarUX.dockedTopPadding : 0)
            .background(
                .regularMaterial.opacity(model.docked ? 1 : 0)
            )
            .offset(y: model.hidden ? 150 : 0)
        }
        .onAnimationCompleted(for: model.hidden) {
            model.doneAnimatingHidden = true
        }
    }
}
