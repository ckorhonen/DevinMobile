import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint: Sendable {
    // Sessions
    case listSessions(limit: Int?, offset: Int?, userEmail: String?)
    case getSession(id: String)
    case createSession
    case deleteSession(id: String)

    // Messages (v1: singular "message" for send)
    case sendMessage(sessionId: String)

    // Knowledge
    case listKnowledge
    case createNote
    case updateNote(id: String)
    case deleteNote(id: String)

    // Playbooks
    case listPlaybooks
    case getPlaybook(id: String)
    case createPlaybook
    case updatePlaybook(id: String)
    case deletePlaybook(id: String)

    // Secrets
    case listSecrets
    case createSecret
    case deleteSecret(id: String)

    // Attachments
    case uploadAttachment
    case listSessionAttachments(sessionId: String)

    // Consumption
    case consumption(dateStart: String?, dateEnd: String?)

    // V3 endpoints
    case listSessionsV3(first: Int?, after: String?)

    var path: String {
        switch self {
        case .listSessions, .createSession, .listSessionsV3:
            return "/sessions"
        case .getSession(let id), .deleteSession(let id):
            return "/sessions/\(id)"
        case .sendMessage(let sessionId):
            return "/sessions/\(sessionId)/message"
        case .uploadAttachment:
            return "/attachments"
        case .listSessionAttachments(let sessionId):
            return "/sessions/\(sessionId)/attachments"
        case .listKnowledge, .createNote:
            return "/knowledge"
        case .updateNote(let id), .deleteNote(let id):
            return "/knowledge/\(id)"
        case .listPlaybooks, .createPlaybook:
            return "/playbooks"
        case .getPlaybook(let id), .updatePlaybook(let id), .deletePlaybook(let id):
            return "/playbooks/\(id)"
        case .listSecrets, .createSecret:
            return "/secrets"
        case .deleteSecret(let id):
            return "/secrets/\(id)"
        case .consumption:
            return "/enterprise/consumption"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listSessions, .getSession, .listKnowledge,
             .listPlaybooks, .getPlaybook, .listSecrets, .consumption,
             .listSessionsV3, .listSessionAttachments:
            return .get
        case .createSession, .sendMessage, .createNote, .createPlaybook, .createSecret,
             .uploadAttachment:
            return .post
        case .updateNote, .updatePlaybook:
            return .put
        case .deleteSession, .deleteNote, .deletePlaybook, .deleteSecret:
            return .delete
        }
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        switch self {
        case .listSessions(let limit, let offset, let userEmail):
            if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
            if let offset { items.append(URLQueryItem(name: "offset", value: String(offset))) }
            if let userEmail { items.append(URLQueryItem(name: "user_email", value: userEmail)) }
        case .consumption(let dateStart, let dateEnd):
            if let dateStart { items.append(URLQueryItem(name: "date_start", value: dateStart)) }
            if let dateEnd { items.append(URLQueryItem(name: "date_end", value: dateEnd)) }
        case .listSessionsV3(let first, let after):
            if let first { items.append(URLQueryItem(name: "first", value: String(first))) }
            if let after { items.append(URLQueryItem(name: "after", value: after)) }
        default:
            break
        }
        return items
    }

    var baseURL: String {
        switch self {
        case .listSessionsV3:
            return APIConfiguration.v3BaseURL ?? APIConfiguration.baseURL
        default:
            return APIConfiguration.baseURL
        }
    }
}
