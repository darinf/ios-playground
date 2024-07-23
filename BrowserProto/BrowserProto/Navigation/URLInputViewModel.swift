import Combine
import Foundation

final class URLInputViewModel: ObservableObject {
    enum Visibility {
        case showing(initialValue: String)
        case hidden
    }

    struct Suggestion: Identifiable {
        let text: String
        // TODO: Add icon

        var id: String { text }
    }

    @Published var visibility: Visibility = .hidden
    @Published var suggesting: Bool = false
    @Published var suggestions: [Suggestion] = []

    func updateSuggestions(for input: String) {
        Task { @MainActor in
            do {
                suggestions = try await SearchEngine.querySuggestions(for: input).map { .init(text: $0) }
            } catch {
                print(">>> error querying suggestions: \(error)")
            }
        }
    }
}
