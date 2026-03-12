import Foundation

enum TopicCollectionFilter: String, CaseIterable, Identifiable {
    case all
    case unstarted
    case needsReview
    case mastered
    case failedRecently

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todos"
        case .unstarted:
            return "Sin empezar"
        case .needsReview:
            return "Reforzar"
        case .mastered:
            return "Dominados"
        case .failedRecently:
            return "Errores recientes"
        }
    }
}

enum LibraryCollectionFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todo"
        case .favorites:
            return "Favoritos"
        }
    }
}

enum QuizSessionLength: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twenty = 20
    case full = 0

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .five:
            return "5"
        case .ten:
            return "10"
        case .twenty:
            return "20"
        case .full:
            return "Todo"
        }
    }

    var questionLimit: Int? {
        rawValue == 0 ? nil : rawValue
    }
}

enum QuizQuestionSelectionStrategy: Equatable {
    case standard
    case recentMistakes
}

enum QuizLaunchBehavior: Equatable {
    case configureOnly
    case autoStart
}

enum QuizPresentationMode: String, Codable, Equatable {
    case practice
    case exam

    var title: String {
        switch self {
        case .practice:
            return "Practica guiada"
        case .exam:
            return "Simulacion de examen"
        }
    }

    var subtitle: String {
        switch self {
        case .practice:
            return "Feedback inmediato para reforzar aprendizaje en el momento."
        case .exam:
            return "Sin correccion inmediata, enfocado en evaluar retencion real."
        }
    }
}

struct QuizSessionRequest: Identifiable, Equatable {
    let topic: QuizTopic
    let strategy: QuizQuestionSelectionStrategy
    let questionLimit: Int?
    let presentationMode: QuizPresentationMode
    let launchBehavior: QuizLaunchBehavior

    var id: String {
        "\(topic.id)-\(strategyKey)-\(questionLimit ?? 0)-\(presentationMode.rawValue)-\(launchBehaviorKey)"
    }

    init(
        topic: QuizTopic,
        strategy: QuizQuestionSelectionStrategy = .standard,
        questionLimit: Int? = nil,
        presentationMode: QuizPresentationMode = .practice,
        launchBehavior: QuizLaunchBehavior = .configureOnly
    ) {
        self.topic = topic
        self.strategy = strategy
        self.questionLimit = questionLimit
        self.presentationMode = presentationMode
        self.launchBehavior = launchBehavior
    }

    private var strategyKey: String {
        switch strategy {
        case .standard:
            return "standard"
        case .recentMistakes:
            return "recentMistakes"
        }
    }

    private var launchBehaviorKey: String {
        switch launchBehavior {
        case .configureOnly:
            return "configure"
        case .autoStart:
            return "auto"
        }
    }
}

struct QuestionAttemptRecord: Codable, Hashable {
    let questionID: UUID
    let topicID: String
    let answeredAt: Date
    let selectedAnswer: String
    let wasCorrect: Bool
}

struct QuestionReviewItem: Identifiable, Hashable {
    let id: UUID
    let prompt: String
    let correctAnswer: String
    let selectedAnswer: String
    let explanation: String
    let wasCorrect: Bool
}
