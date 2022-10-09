// Copyright 2022 Darin Fisher. All rights reserved.

import Combine

class ZeroQueryViewModel: ObservableObject {
    enum Target { case existingCard, newCard }

    let urlFieldViewModel = UrlFieldViewModel()
    var target: Target = .existingCard
}
