import Combine

final class SuggestionsViewModel {
    struct Suggestion: Identifiable {
        let text: String
        // TODO: Add icon

        var id: String { text }
    }

    @Published var suggestions: [Suggestion] = []
}
