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
    }

    func resetHeight() {
        withAnimation {
            height = defaultHeight
        }
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
        self.subscription = scrollViewObserver.$panning
            .combineLatest(
                scrollViewObserver.$direction,
                scrollViewObserver.$panDelta,
                scrollViewObserver.$scrolledToTop
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] panning, direction, panDelta, scrolledToTop in
                self?.updateHeight(
                    panning: panning,
                    direction: direction,
                    panDelta: panDelta,
                    scrolledToTop: scrolledToTop
                )
            }
    }

    private func updateHeight(
        panning: Bool,
        direction: ScrollViewObserver.ScrollDirection,
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
        } else if overlayModel.height < overlayModel.defaultHeight {
            withAnimation(animation) {
                overlayModel.height = direction == .down ? 0 : overlayModel.defaultHeight
            }
        }
    }
}
