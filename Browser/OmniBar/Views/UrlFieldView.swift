// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct UrlFieldView: View {
    @ObservedObject var model: UrlFieldViewModel
    let namespace: Namespace.ID
    var editable = false
    var submit: (() -> Void)? = nil

    @FocusState var hasFocus: Bool

    var displayText: String {
        // If model.input is a URL string, then extract just the hostname.
        guard let url = URL(string: model.input) else {
            return model.input
        }
        return url.host ?? model.input
    }
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                Color(uiColor: .systemBackground)
                    .matchedGeometryEffect(id: "urlField.background", in: namespace)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.cyan)
                        .matchedGeometryEffect(id: "urlField.progress", in: namespace)
                        .frame(width: geom.size.width * model.progress)
                        .opacity(model.isLoading ? 1 : 0)
                    Spacer()
                }
            }
        }
        .cornerRadius(25)
        .matchedGeometryEffect(id: "urlField.background-clip", in: namespace)
        .shadow(radius: OmniBarUX.shadowRadius)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .overlay(
            Group {
                if editable {
                    TextField("Search or enter address", text: $model.input)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($hasFocus)
                        .matchedGeometryEffect(id: "urlField.text", in: namespace)
                        .onReceive(model.$hasFocus) {
                            hasFocus = $0
                        }
                        .onAppear {
                            model.hasFocus = true
                        }
                        .onSubmit {
                            submit?()
                        }
                } else {
                    Text(displayText)
                        .font(.footnote)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .matchedGeometryEffect(id: "urlField.text", in: namespace)
                        .foregroundColor(OmniBarUX.textColor)
                }
            }
            .padding([.leading, .trailing], 8)
        )
    }
}
