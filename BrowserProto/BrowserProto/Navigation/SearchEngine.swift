import Foundation

enum SearchEngine {
    static func querySuggestions(for input: String) async throws -> [String] {
        guard let url = URL(string: "https://google.com/complete/search?client=chrome&q=\(escaped(input))") else { return [] }
        let (jsonData, _) = try await URLSession.shared.data(from: url)

        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        guard let jsonArray = jsonObject as? [Any], let suggestions = jsonArray[1] as? [String] else { return [] }

        return suggestions
    }

    private static func escaped(_ input: String) -> String {
        input.replacingOccurrences(of: " ", with: "+")
    }
}
