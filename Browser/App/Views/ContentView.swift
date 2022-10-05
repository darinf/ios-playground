//
//  ContentView.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/3/22.
//

import SwiftUI

struct ContentView: View {
    let cards: [ColorCardModel] = [
        .init(title: "First", color: .systemBlue),
        .init(title: "Second", color: .systemPink),
        .init(title: "Third", color: .systemPurple),
        .init(title: "Fourth", color: .systemTeal),
        .init(title: "Fifth", color: .systemOrange),
        .init(title: "Sixth", color: .systemGreen),
        .init(title: "Seventh", color: .systemIndigo),
        .init(title: "Eighth", color: .systemRed),
        .init(title: "Ninth", color: .systemBrown)
    ]

    @Namespace var namespace
    @State var selectedCardId: String?
    @State var zoomed: Bool = false
    @StateObject var selectedCardDecorationsModel = SelectedCardDecorationsModel()

    var body: some View {
        ZStack {
            CardGridView(namespace: namespace, cards: cards, selectedCardId: $selectedCardId, zoomed: $zoomed)

            if let selectedCardId = selectedCardId {
                if let card = cards.first(where: { $0.id == selectedCardId }), zoomed {
                    FullCardView(namespace: namespace, card: card, zoomed: $zoomed)
                }
            }
        }
        .environmentObject(selectedCardDecorationsModel)
        .onAppear {
            selectedCardId = cards[0].id
        }
    }
}
