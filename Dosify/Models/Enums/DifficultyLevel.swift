import Foundation

enum DifficultyLevel: String, CaseIterable, Codable, Identifiable, Comparable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:
            return "Facil"
        case .medium:
            return "Media"
        case .hard:
            return "Dificil"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .easy:
            return 0
        case .medium:
            return 1
        case .hard:
            return 2
        }
    }

    var sortOrderValue: Int {
        sortOrder
    }

    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
