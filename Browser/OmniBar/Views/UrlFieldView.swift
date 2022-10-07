// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct UrlFieldView: View {
    @ObservedObject var model: UrlFieldViewModel
    let namespace: Namespace.ID
    var editable = false
    var submit: (() -> Void)? = nil

    @FocusState var hasFocus: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "urlField", in: namespace)
            .frame(height: 40)
            .shadow(radius: OmniBarUX.shadowRadius)
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
                        Text(model.input)
                            .matchedGeometryEffect(id: "urlField.text", in: namespace)
                    }
                }
                .padding([.leading, .trailing], 8)
            )
    }
}
