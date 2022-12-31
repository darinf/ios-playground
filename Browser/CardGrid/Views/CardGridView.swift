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
                                case .activate:
                                    model.activateCard(byId: cardDetail.id)
                                case .close:
                                    model.closeCard(byId: cardDetail.id)
                                case .move(let direction):
                                    model.moveCard(cardDetail, direction: direction, geom: geom)
                                    withAnimation {
                                        scroller.scrollTo(cardDetail.id)
                                    }
                                case .press(let frame):
                                    model.draggingModel.startDragging(card: cardDetail.model, frame: frame)
                                    break
                                case .pressEnded:
                                    model.draggingModel.stopDragging()
                                    break
                                }
                            }
                            .id(cardDetail.id)
                        }
                    }
                    .overlay(
                        CardDraggingView<Card>(
                            model: model.draggingModel,
                            selectedCardId: model.selectedCardId
                        ),
                        alignment: .topLeading
                    )
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
                    .simultaneousGesture(DragGesture()
                        .onChanged {
                            model.draggingModel.translation = $0.translation
                        }
                    )
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

struct CardDraggingView<Card>: View where Card: CardModel {
    // Use a custom namespace here since we don't want SwiftUI to link this `CardView`
    // to the one used by `SmallCardView`. Let them be completely independent.
    @Namespace var namespace

    @ObservedObject var model: CardDraggingModel<Card>
    let selectedCardId: Card.ID?

    var body: some View {
        if let card = model.draggingCard?.card {
            let cardViewModel = CardViewModel(card: card, pressed: true)
            CardView(
                namespace: namespace,
                model: cardViewModel,
                selected: model.draggingCard?.card.id == selectedCardId,
                zoomed: false
            )
            .frame(width: model.frame.width, height: model.frame.height, alignment: .center)
            .overlay(CloseButtonView<Card>(namespace: namespace, model: cardViewModel))
            .offset(
                x: model.frame.minX + model.translation.width,
                y: model.frame.minY + model.translation.height
            )
            .opacity(model.draggingCard == nil ? 0 : 0.7)
        }
    }
}
