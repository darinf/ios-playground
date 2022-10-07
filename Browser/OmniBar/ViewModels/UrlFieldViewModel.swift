// Copyright 2022 Darin Fisher. All rights reserved.

import Combine

class UrlFieldViewModel: ObservableObject {
    @Published var input = ""
    @Published var hasFocus = false
}
