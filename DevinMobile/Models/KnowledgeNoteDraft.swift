import FoundationModels

@Generable
struct KnowledgeNoteDraft: Codable, Sendable {
    @Guide(description: "A short descriptive name for the knowledge note, e.g. 'Database migration pattern' or 'Auth token refresh flow'")
    var name: String

    @Guide(description: "When Devin should apply this knowledge, e.g. 'When working on database migrations' or 'When implementing authentication'")
    var trigger: String

    @Guide(description: "The knowledge content — reusable instructions, patterns, or best practices extracted from the conversation")
    var body: String
}
