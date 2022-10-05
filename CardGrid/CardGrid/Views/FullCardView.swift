//
//  FullCardView.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/4/22.
//

import SwiftUI

struct FullCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let card: Card
    @Binding var zoomed: Bool

    var body: some View {
        CardView(namespace: namespace, card: card, selected: true, zoomed: true)
            .zIndex(1)
            .ignoresSafeArea()
            .transition(.identity.animation(.default))
            .onTapGesture {
                withAnimation(CardUX.animation) {
                    self.zoomed = false
                }
            }
    }
}
