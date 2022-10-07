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
    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool

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

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: card.thumbnail)
                .resizable()
                .matchedGeometryEffect(id: "\(card.id).thumbnail", in: namespace)
                .cornerRadius(cardRadius)
                .matchedGeometryEffect(id: "\(card.id).thumbnail-corners", in: namespace)
                .shadow(radius: shadowRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cardRadius)
                        .stroke(Color(UIColor.label).opacity(selected && showDecorations ? 1 : 0), lineWidth: 3)
                        .matchedGeometryEffect(id: "\(card.id).selection-border", in: namespace)
                )
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
