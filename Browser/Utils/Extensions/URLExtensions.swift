// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation

extension URL {
    init?(string: String?) {
        guard let string = string else { return nil }
        self.init(string: string)
    }
}
