// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum OmniBarUX {
    static let shadowRadius: CGFloat = 2
    static let transitionAnimation = Animation.interactiveSpring()
    static let textColor = Color(uiColor: .label)
}

struct OmniBarView: View {
    enum Action {
        case urlField, newCard, showCards, showMenu
    }

    @ObservedObject var model: OmniBarViewModel
    let namespace: Namespace.ID
    let zoomed: Bool
    let handler: (_ action: Action) -> Void

    @ViewBuilder
    var urlField: some View {
        UrlFieldView(model: model.urlFieldViewModel, namespace: namespace)
    }

    @ViewBuilder
    var newCard: some View {
        NewCardView(namespace: namespace)
    }

    @ViewBuilder
    var showCards: some View {
        ShowCardsView(namespace: namespace)
    }

    @ViewBuilder
    var showMenu: some View {
        ShowMenuView(namespace: namespace)
    }

    @ViewBuilder
    var expando: some View {
        ExpandoView(namespace: namespace)
    }

    @ViewBuilder
    var expandedLayout: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    handler(.showMenu)
                } label: {
                    showMenu
                }
                .padding(.trailing, 5)
            }
            HStack {
                Button {
                    handler(.urlField)
                } label: {
                    urlField
                }
                .zIndex(1)
                .frame(maxWidth: .infinity)
                .padding(.leading, 25)

                Button {
                    handler(.newCard)
                } label: {
                    newCard
                }

                Button {
                    handler(.showCards)
                } label: {
                    showCards
                }

                Button {
                    withAnimation(OmniBarUX.transitionAnimation) {
                        model.expanded.toggle()
                    }
                } label: {
                    expando
                }
            }
        }
        .padding(.trailing, 25)
    }

    @ViewBuilder
    var compactLayout: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(OmniBarUX.transitionAnimation) {
                    model.expanded.toggle()
                }
            } label: {
                ZStack {
                    urlField
                        .frame(width: 40)
                    newCard
                    showCards
                    showMenu
                    expando
                }
            }
            .padding(.trailing, 25)
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Group {
                if model.expanded {
                    expandedLayout
                } else {
                    compactLayout
                }
            }
            .padding(.bottom, 50)
            .offset(y: model.hidden ? 150 : 0)
        }
    }
}
