// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum OmniBarUX {
    static let shadowRadius: CGFloat = 2
    static let transitionAnimation = Animation.interactiveSpring()
}

struct OmniBarView: View {
    enum Action {
        case urlField, showTabs, showMenu
    }

    @Namespace var namespace
    @ObservedObject var model: OmniBarViewModel
    let zoomed: Bool
    let handler: (_ action: Action) -> Void

    @ViewBuilder
    var urlField: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "urlField", in: namespace)
            .frame(height: 40)
            .shadow(radius: OmniBarUX.shadowRadius)
    }

    @ViewBuilder
    var showTabs: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "showTabs.circle", in: namespace)
            .frame(height: 40)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "square.on.square")
                    .matchedGeometryEffect(id: "showTabs.icon", in: namespace)
            )
    }

    @ViewBuilder
    var showMenu: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "menu.circle", in: namespace)
            .frame(height: 40)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "rectangle.grid.1x2")
                    .matchedGeometryEffect(id: "menu.icon", in: namespace)
            )
    }

    var body: some View {
        Group {
            if model.expanded {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            handler(.showMenu)
                        } label: {
                            showMenu
                        }
                        .padding(.trailing, 5)
                    }
                    HStack {
                        Button {
                            handler(.urlField)
                        } label: {
                            urlField
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 25)

                        Button {
                            handler(.showTabs)
                        } label: {
                            showTabs
                        }

                        Button {
                            withAnimation(OmniBarUX.transitionAnimation) {
                                model.expanded.toggle()
                            }
                        } label: {
                            Circle()
                                .fill(Color(uiColor: .systemBackground))
                                .matchedGeometryEffect(id: "E", in: namespace)
                                .frame(height: 50)
                                .shadow(radius: OmniBarUX.shadowRadius)
                        }
                    }
                }
                .padding(.trailing, 25)
            } else {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(OmniBarUX.transitionAnimation) {
                            model.expanded.toggle()
                        }
                    } label: {
                        ZStack {
                            urlField
                                .frame(width: 40)
                            showTabs
                            showMenu
                            Circle()
                                .fill(Color(uiColor: .systemBackground))
                                .matchedGeometryEffect(id: "E", in: namespace)
                                .frame(height: 50)
                                .shadow(radius: OmniBarUX.shadowRadius)
                        }
                    }
                    .padding(.trailing, 25)
                }
            }
        }
        .padding(.bottom, 50)
        .offset(y: zoomed ? 0 : 150)
    }
}
