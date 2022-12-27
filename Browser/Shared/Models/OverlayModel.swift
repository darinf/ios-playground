// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation
import SwiftUI
import UIKit

class OverlayModel: ObservableObject {
    let defaultHeight: CGFloat
    @Published var height: CGFloat = 0

    private var observers: Set<ScrollViewObserver> = []

    init(defaultHeight: CGFloat) {
        self.defaultHeight = defaultHeight
        self.height = defaultHeight
    }

    func resetHeight() {
        height = defaultHeight
    }
}

// Use an instance of this class to update `OverlayModel.height`.
class OverlayUpdater {
    private let scrollViewObserver: ScrollViewObserver
    private let overlayModel: OverlayModel
    private var subscription: AnyCancellable?

    init(scrollView: UIScrollView, overlayModel: OverlayModel) {
        self.scrollViewObserver = .init(scrollView: scrollView)
        self.overlayModel = overlayModel
        self.subscription = Publishers.CombineLatest3(
            scrollViewObserver.$panning,
            scrollViewObserver.$panDelta,
            scrollViewObserver.$scrolledToTop
        )
        .dropFirst()
        .sink { [weak self] panning, panDelta, scrolledToTop in
            guard let self else { return }
            self.updateHeight(
                panning: panning,
                panDelta: panDelta,
                scrolledToTop: scrolledToTop
            )
        }
    }

    private func updateHeight(
        panning: Bool,
        panDelta: CGFloat,
        scrolledToTop: Bool
    ) {
        let animation = Animation.easeInOut(duration: 0.2)

        if scrolledToTop {
            withAnimation(animation) {
                overlayModel.height = overlayModel.defaultHeight
            }
            return
        }

        if panning {
            // We're already in an interactive state, so no need to animate.
            overlayModel.height = min(max(overlayModel.height - panDelta, 0), overlayModel.defaultHeight)
        } else if overlayModel.height > 0 {
            withAnimation(animation) {
                overlayModel.height = overlayModel.defaultHeight
            }
        }
    }
}
