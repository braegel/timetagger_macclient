import Foundation

@MainActor
final class TagSuggestionsViewModel: ObservableObject {
    @Published var suggestions: [[String]] = []

    // TODO: Phase 6 — analyze tag frequency from TimeTagger history
}
