import FoundationModels

@Generable
struct SessionSummary: Codable, Sendable {
    @Guide(description: "A concise 1-2 sentence summary of what was accomplished or discussed in this session")
    var text: String
}
