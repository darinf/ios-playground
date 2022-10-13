// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum CardUX {
    static let aspectRatio = CGSize(width: 3, height: 3.5)
    static let titleHeight: CGFloat = 16
    static let iconRadius: CGFloat = 2
    static let cardRadius: CGFloat = 16
    static let shadowRadius: CGFloat = 2
    static let verticalSpacing: CGFloat = 10
    static let minimumCardWidth: CGFloat = 140
    static let transitionAnimation = Animation.interactiveSpring(response: 0.25)
    static let decorationAnimation = Animation.easeInOut(duration: 0.1)
    static let pressAnimation = Animation.easeOut
}

struct CardView<Card>: View where Card: CardModel {
    enum Action { case activated, closed }

    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    var handler: ((_ action: Action) -> Void)? = nil

    var card: Card {
        model.card
    }
    var showDecorations: Bool {
        model.showDecorations
    }
    var cardRadius: CGFloat {
        showDecorations ? CardUX.cardRadius : 0
    }
    var shadowRadius: CGFloat {
        showDecorations ? CardUX.shadowRadius : 0
    }

    var thumbnail: some View {
        // Image thumbnail as background so we can clip it.
        Button {
            handler?(.activated)
        } label: {
            Color.clear
                .matchedGeometryEffect(id: "\(card.id).thumbnail-container", in: namespace)
                .background(alignment: .topLeading) {
                    Image(uiImage: card.thumbnail)
                        .resizable()
                        .scaledToFill()
                        .matchedGeometryEffect(id: "\(card.id).thumbnail", in: namespace)
                }
                .clipped()
                .matchedGeometryEffect(id: "\(card.id).thumbnail-clip", in: namespace)
                .cornerRadius(cardRadius)
                .matchedGeometryEffect(id: "\(card.id).thumbnail-corners", in: namespace)
                .shadow(radius: shadowRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cardRadius)
                        .stroke(Color(UIColor.label).opacity(selected && showDecorations ? 1 : 0), lineWidth: 3)
                        .matchedGeometryEffect(id: "\(card.id).selection-border", in: namespace)
                )
                // Prevent the clipped part of the thumbnail from contributing to the hit box.
                .contentShape(RoundedRectangle(cornerRadius: cardRadius))
                .matchedGeometryEffect(id: "\(card.id).content-shape", in: namespace)
        }
        .buttonStyle(.reportsPresses(pressed: $model.pressed))
        .matchedGeometryEffect(id: "\(card.id).thumbnail-button", in: namespace)        
    }

    var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    handler?(.closed)
                } label: {
                    Circle()
                        .fill(Color(uiColor: .systemGroupedBackground))
                        .matchedGeometryEffect(id: "\(card.id).closebutton", in: namespace)
                        .frame(height: 22)
                        .overlay(
                            Image(systemName: "multiply")
                                .foregroundColor(Color(uiColor: .label))
                                .matchedGeometryEffect(id: "\(card.id).closebutton-icon", in: namespace)
                        )
                        .opacity(showDecorations ? 1 : 0)
                        .padding([.top, .trailing], 6)
                }
            }
            Spacer()
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            thumbnail
            closeButton

            HStack {
                Image(uiImage: card.favicon)
                    .resizable()
                    .matchedGeometryEffect(id: "\(card.id).favicon", in: namespace)
                    .frame(width: CardUX.titleHeight, height: CardUX.titleHeight)
                    .cornerRadius(CardUX.iconRadius)
                    .matchedGeometryEffect(id: "\(card.id).favicon-corners", in: namespace)
                Text(card.title)
                    .font(.system(size: CardUX.titleHeight))
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "\(card.id).title", in: namespace)
            }
            .frame(maxWidth: CardUX.minimumCardWidth)
            .offset(x: 0, y: CardUX.titleHeight + CardUX.verticalSpacing)
            .opacity(showDecorations ? 1 : 0)
        }
        .scaleEffect(model.pressed ? 0.95 : 1)
        .animation(CardUX.pressAnimation, value: model.pressed)
        // Update showDecorations if the card is appearing or disappearing. This ensures
        // consistency as sometimes a view is not removed right away.
        .onAppear {
            withAnimation(CardUX.decorationAnimation) {
                model.showDecorations = !zoomed
            }
        }
        .onDisappear {
            withAnimation(CardUX.decorationAnimation) {
                model.showDecorations = zoomed
            }
        }
    }
}
