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
        GeometryReader { geom in
            ScrollView(showsIndicators: false) {
                ScrollViewReader { scroller in
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
                                    model.activateCard(byId: cardDetail.id)
                                case .closed:
                                    model.closeCard(byId: cardDetail.id)
                                case .move(let direction):
                                    model.moveCard(cardDetail, direction: direction, geom: geom)
                                }
                            }
                            .id(cardDetail.id)
                        }
                    }
                    .coordinateSpace(name: "grid")
                    .padding(CardGridUX.spacing)
                    .onAppear {
                        if let id = model.selectedCardId {
                            scroller.scrollTo(id)
                        }
                    }
                    .onChange(of: model.selectedCardId) { id in
                        scroller.scrollTo(id)
                    }
                    .onChange(of: model.scrollToSelectedCardId) { _ in
                        scroller.scrollTo(model.selectedCardId)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .introspectScrollView { scrollView in
                model.observeScrollView(scrollView)
            }
            .background(Color(uiColor: .systemBackground))
        }
    }

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .top) {
                grid
                    .onAnimationCompleted(for: model.zoomed) {
                        model.onZoomCompleted()
                    }

                Color.clear.background(.regularMaterial)
                    .frame(height: geom.safeAreaInsets.top)
                    .ignoresSafeArea()
                    .zIndex(2)

                if let details = model.selectedCardDetails {
                    if model.zoomed {
                        FullCardView(
                            namespace: namespace,
                            model: details.model
                        )
                        // Stacked behind the FullCardView during the zoom animation.
                        zoomedCard(details.model.card)
                            .ignoresSafeArea(edges: .bottom)
                            .zIndex(model.showContent ? 1 : -1)
                            .transition(.identity)
                    }
                }

                overlay(model.zoomed)
                    .ignoresSafeArea(edges: [.top, .bottom])
                    .zIndex(2)
            }
        }
    }
}
