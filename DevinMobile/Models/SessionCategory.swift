import FoundationModels
import SwiftUI

@Generable
enum SessionCategory: String, Codable, CaseIterable, Sendable {
    case bug
    case feature
    case refactor
    case performance
    case docs
    case infra
    case question
    case other
}

extension SessionCategory {
    var label: String {
        switch self {
        case .bug: "Bug"
        case .feature: "Feature"
        case .refactor: "Refactor"
        case .performance: "Performance"
        case .docs: "Docs"
        case .infra: "Infra"
        case .question: "Question"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .bug: "ladybug"
        case .feature: "sparkles"
        case .refactor: "arrow.triangle.2.circlepath"
        case .performance: "gauge.high"
        case .docs: "doc.text"
        case .infra: "server.rack"
        case .question: "questionmark.bubble"
        case .other: "ellipsis"
        }
    }

    var color: Color {
        switch self {
        case .bug: .devinRed
        case .feature: .devinGreen
        case .refactor: .devinBlue
        case .performance: .devinOrange
        case .docs: .devinPurple
        case .infra: .devinGray
        case .question: .devinYellow
        case .other: .secondary
        }
    }
}
