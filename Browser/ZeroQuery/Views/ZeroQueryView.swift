// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ZeroQueryView: View {
    enum Action { case navigate(input: String), cancel }

    let model: ZeroQueryViewModel
    let namespace: Namespace.ID
    let handler: (_ action: Action) -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    model.urlFieldViewModel.hasFocus = false
                    handler(.cancel)
                } label: {
                    Text("Cancel")
                        .padding(.trailing, 15)
                }
            }
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .trailing) {
                    Group {
                        NewCardView(namespace: namespace, height: 20)
                        ShowCardsView(namespace: namespace, height: 20)
                        ShowMenuView(namespace: namespace, height: 20)
                        ExpandoView(namespace: namespace, height: 20)
                    }
                    .padding(.trailing, 5)
                    UrlFieldView(model: model.urlFieldViewModel, namespace: namespace, editable: true, submit: {
                        handler(.navigate(input: model.urlFieldViewModel.input))
                    })
                }
                .padding(.trailing, 15)
            }
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
