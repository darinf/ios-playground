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
    static let animation = Animation.interpolatingSpring(stiffness: 425, damping: 30)
}

struct CardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let card: Card
    let selected: Bool
    let zoomed: Bool

    @EnvironmentObject var selectedCardDecorationsModel: SelectedCardDecorationsModel

    var showDecorations: Bool {
        !selected || selectedCardDecorationsModel.showDecorations
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
                    .matchedGeometryEffect(id: "\(card.id).title", in: namespace)
            }
            .offset(x: 0, y: CardUX.titleHeight + CardUX.verticalSpacing)
            .opacity(showDecorations ? 1 : 0)
        }
        .onAppear {
            guard selected else { return }
            withAnimation(.easeInOut) {
                selectedCardDecorationsModel.showDecorations = !zoomed
            }
        }
    }
}
