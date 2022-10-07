// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct BrowserView: View {
    @ObservedObject var model: BrowserViewModel

    @ViewBuilder
    func bottomOverlay(zoomed: Bool) -> some View {
        OmniBarView(model: model.omniBarViewModel, zoomed: zoomed) { action in
            switch action {
            case .urlField:
                print(">>> urlField")
            case .showTabs:
                model.cardGridViewModel.zoomOut()
            case .showMenu:
                print(">>> showMenu")
            }
        }
    }

    @ViewBuilder
    func cardContent(card: ColorCardModel) -> some View {
        Color.gray
    }

    var body: some View {
        ZStack {
            CardGridView(
                model: model.cardGridViewModel,
                cardContent: cardContent,
                bottomOverlay: bottomOverlay
            )
        }
    }
}
