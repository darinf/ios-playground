// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation

class UrlFixup {
    static func fromUser(input: String) -> URL? {
        var url: URL? = nil

        // Assume input is likely a URL if it contains either of these characters.
        if input.contains(".") || input.contains("/") {
            if input.starts(with: "https://") || input.starts(with: "http://") {
                url = URL(string: input)
            } else {
                url = URL(string: "http://\(input)")
            }
        }

        if url == nil {
            // Conduct a search instead
            let escaped = input.replacingOccurrences(of: " ", with: "+")
            url = URL(string: "https://neeva.com/search?q=\(escaped)")
        }

        return url
    }
}
