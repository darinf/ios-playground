// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct BrowserView: View {
    @Namespace var namespace
    @ObservedObject var model: BrowserViewModel

    @ViewBuilder
    func overlay(zoomed: Bool) -> some View {
        if !model.showZeroQuery {
            OmniBarView(model: model.omniBarViewModel, namespace: namespace, zoomed: zoomed) { action in
                switch action {
                case .urlField:
                    model.presentZeroQuery(target: .existingCard)
                case .newCard:
                    model.presentZeroQuery(target: .newCard)
                    break
                case .showCards:
                    if zoomed {
                        model.cardGridViewModel.zoomOut()
                    } else {
                        model.cardGridViewModel.zoomIn()
                    }
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
                model.handleZeroQueryAction(action)
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
                overlay: overlay,
                zoomedCard: zoomedCard
            )
            zeroQuery()
        }
    }
}
