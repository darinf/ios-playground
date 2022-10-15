// Copyright 2022 Darin Fisher. All rights reserved.

import Introspect
import SwiftUI

enum CardGridUX {
    static let spacing: CGFloat = 18
}

struct CardGridView<Card, ZoomedContent, OverlayContent>: View where Card: CardModel, ZoomedContent: View, OverlayContent: View {
    @Namespace var namespace
    @ObservedObject var model: CardGridViewModel<Card>
    @ViewBuilder let overlay: (_ zoomed: Bool) -> OverlayContent
    @ViewBuilder let zoomedCard: (_ card: Card) -> ZoomedContent

    var grid: some View {
        ScrollView(showsIndicators: false) {
            let columns = [
                GridItem(.adaptive(minimum: CardUX.minimumCardWidth),
                         spacing: CardGridUX.spacing)
            ]
            LazyVGrid(columns: columns, spacing: CardGridUX.spacing + CardUX.titleHeight + CardUX.verticalSpacing) {
                ForEach(model.allDetails) { cardDetail in
                    let selected = model.selectedCardId == cardDetail.id
                    SmallCardView(
                        namespace: namespace,
                        model: cardDetail.model,
                        selected: selected,
                        zoomed: model.zoomed
                    ) { action in
                        switch action {
                        case .activated:
                            model.activateCard(id: cardDetail.id)
                        case .closed:
                            model.closeCard(id: cardDetail.id)
                        }
                    }
                }
            }
            .padding(CardGridUX.spacing)
        }
        .introspectScrollView { scrollView in
            model.observe(scrollView: scrollView)
        }
        .background(Color(uiColor: .systemBackground))
    }

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .top) {
                grid
                    .onAnimationCompleted(for: model.zoomed) {
                        model.onZoomCompleted()
                    }

                Color(uiColor: .systemBackground)
                    .frame(height: geom.safeAreaInsets.top)
                    .offset(y: model.zoomed ? 0 : -geom.safeAreaInsets.top)
                    .ignoresSafeArea()
                    .zIndex(2)

                if let details = model.selectedCardDetails {
                    if model.zoomed {
                        FullCardView(
                            namespace: namespace,
                            model: details.model
                        )
                    }

                    // The selected tab is always loaded so we can seamlessly just
                    // move it to the foreground when zoomed. This happens only
                    // after the FullCardView transition completes via showContent.
                    zoomedCard(details.model.card)
                        .ignoresSafeArea(edges: .bottom)
                        .zIndex(model.zoomed && model.showContent ? 1 : -1)
                }

                overlay(model.zoomed)
                    .ignoresSafeArea(edges: [.top, .bottom])
                    .zIndex(2)
            }
            .onAppear {
                if !model.allDetails.isEmpty {
                    model.selectCardDetails(details: model.allDetails[0])
                }
            }
        }
    }
}
