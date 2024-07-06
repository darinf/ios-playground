import Foundation

enum URLInput {
    static func url(from text: String) -> URL? {
        let url: URL?
        if text.starts(with: "http://") || text.starts(with: "https://") {
            url = URL(string: text)
        } else {
            url = URL(string: "https://www.google.com/search?q=\(text)")
        }
        return url
    }
}
