import Foundation

struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let hasNextPage: Bool
    let endCursor: String?
    let total: Int?
}
