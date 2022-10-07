// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct BrowserView: View {
    @Namespace var namespace
    @ObservedObject var model: BrowserViewModel

    @ViewBuilder
    func bottomOverlay(zoomed: Bool) -> some View {
        if !model.showZeroQuery {
            OmniBarView(model: model.omniBarViewModel, namespace: namespace, zoomed: zoomed) { action in
                switch action {
                case .urlField:
                    model.presentZeroQuery()
                case .showTabs:
                    model.cardGridViewModel.zoomOut()
                case .showMenu:
                    print(">>> showMenu")
                }
            }
        }
    }

    @ViewBuilder
    func zeroQuery() -> some View {
        if model.showZeroQuery {
            ZeroQueryView(model: model.zeroQueryViewModel, namespace: namespace) { action in
                switch action {
                case .cancel:
                    model.dismissZeroQuery()
                case .navigate(let input):
                    print(">>> navigate to \(input)")
                    model.omniBarViewModel.urlFieldViewModel.input = input
                    model.dismissZeroQuery()

                    if let selectedCard = model.selectedCard {
                        if let url = URL(string: input) {
                            selectedCard.navigate(to: url)
                        } else {
//                            selectedCard.model.card.navigate(to: URL(string: "https://neeva.com/search?q=\(input)")!)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func zoomedCard(card: WebContentsCardModel) -> some View {
        WebContentsView(model: model.webContentsViewModel, card: card)
    }

    var body: some View {
        ZStack {
            CardGridView(
                model: model.cardGridViewModel,
                bottomOverlay: bottomOverlay,
                zoomedCard: zoomedCard
            )
            zeroQuery()
        }
    }
}
