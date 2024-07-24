import Combine
import Foundation

final class URLInputViewModel {
    enum Visibility {
        case showing(initialValue: String)
        case hidden
    }

    let suggestionsViewModel = SuggestionsViewModel()

    @Published var visibility: Visibility = .hidden
    @Published var suggesting: Bool = false

    func updateSuggestions(for input: String) {
        Task { @MainActor in
            do {
                suggestionsViewModel.suggestions = try await SearchEngine.querySuggestions(for: input).map { .init(text: $0) }
            } catch {
                print(">>> error querying suggestions: \(error)")
            }
        }
    }
}
