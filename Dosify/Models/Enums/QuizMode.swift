import Foundation

enum QuizMode: String, CaseIterable, Codable, Identifiable {
    case matching
    case multipleChoice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .matching:
            return "Emparejar"
        case .multipleChoice:
            return "Multiple choice"
        }
    }
}
