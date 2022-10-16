// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum OmniBarUX {
    static let shadowRadius: CGFloat = 2
    static let transitionAnimation = Animation.interactiveSpring()
    static let textColor = Color(uiColor: .label)
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
        UrlFieldView(model: model.urlFieldViewModel, namespace: namespace)
    }

    @ViewBuilder
    var newCardView: some View {
        NewCardView(namespace: namespace)
    }

    @ViewBuilder
    var showCardsView: some View {
        ShowCardsView(namespace: namespace)
    }

    @ViewBuilder
    var showMenuView: some View {
        ShowMenuView(namespace: namespace)
    }

    @ViewBuilder
    func expandoView(height: CGFloat) -> some View {
        ExpandoView(namespace: namespace, height: height)
    }

    // Buttons

    @ViewBuilder
    var urlFieldButtonView: some View {
        InteractiveButton {
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
        InteractiveButton {
            handler(.newCard)
        } label: {
            newCardView
        }
    }

    @ViewBuilder
    var showCardsButtonView: some View {
        InteractiveButton {
            handler(.showCards)
        } label: {
            showCardsView
        }
    }

    @ViewBuilder
    var showMenuButtonView: some View {
//        Menu {
//            Toggle("Docked", isOn: $model.docked)
//        } label: {
//            showMenuView
//        }
//        .menuStyle(.button)
        InteractiveButton {
            withAnimation {
                model.docked.toggle()
            }
        } label: {
            showMenuView
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
                        .frame(width: 40)
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
            .padding(.bottom, 40)
            .padding(.top, model.docked ? 12 : 0)
            .background(
                Group {
                    Color(uiColor: .systemBackground)
                        .matchedGeometryEffect(id: "omniBar.background", in: namespace)
                        .opacity(model.docked ? 0.7 : 0)
                        .animation(.default, value: model.docked)
                        .shadow(radius: 2)
                }
            )
            .offset(y: model.hidden ? 150 : 0)
        }
    }
}
