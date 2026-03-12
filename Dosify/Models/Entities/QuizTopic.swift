import Foundation

struct QuizTopic: Hashable, Identifiable, Codable {
    let system: StudySystem
    let mode: QuizMode
    let difficulty: DifficultyLevel

    var id: String {
        "\(system.rawValue)-\(mode.rawValue)-\(difficulty.rawValue)"
    }

    var title: String {
        "\(mode.title) · \(system.title)"
    }

    var subtitle: String {
        "Nivel \(difficulty.title)"
    }
}

struct QuizSession: Codable, Identifiable, Hashable {
    let id: String
    let topic: QuizTopic
    let questions: [Question]
    let presentationMode: QuizPresentationMode

    init(
        topic: QuizTopic,
        questions: [Question],
        questionLimit: Int? = nil,
        presentationMode: QuizPresentationMode = .practice
    ) throws {
        let normalizedQuestions = questionLimit.map { Array(questions.prefix($0)) } ?? questions

        guard !normalizedQuestions.isEmpty else {
            throw QuizSessionError.missingQuestions(topic: topic)
        }

        for question in normalizedQuestions {
            try question.validateConfiguration(expectedMode: topic.mode)
        }

        self.id = topic.id
        self.topic = topic
        self.questions = normalizedQuestions.shuffled()
        self.presentationMode = presentationMode
    }
}

struct QuizSessionDraft: Codable, Identifiable, Hashable {
    let id: UUID
    let session: QuizSession
    let currentIndex: Int
    let correctAnswers: Int
    let hasAnsweredCurrentQuestion: Bool
    let submittedAnswer: String?
    let selectedAnswer: String?
    let attempts: [QuestionAttemptRecord]

    init(
        id: UUID = UUID(),
        session: QuizSession,
        currentIndex: Int = 0,
        correctAnswers: Int = 0,
        hasAnsweredCurrentQuestion: Bool = false,
        submittedAnswer: String? = nil,
        selectedAnswer: String? = nil,
        attempts: [QuestionAttemptRecord] = []
    ) {
        self.id = id
        self.session = session
        self.currentIndex = currentIndex
        self.correctAnswers = correctAnswers
        self.hasAnsweredCurrentQuestion = hasAnsweredCurrentQuestion
        self.submittedAnswer = submittedAnswer
        self.selectedAnswer = selectedAnswer
        self.attempts = attempts
    }
}

struct QuizSessionResult {
    let topic: QuizTopic
    let totalQuestions: Int
    let correctAnswers: Int
    let attempts: [QuestionAttemptRecord]
    let reviewItems: [QuestionReviewItem]
    let presentationMode: QuizPresentationMode

    var incorrectAnswers: Int {
        totalQuestions - correctAnswers
    }
}

enum QuizSessionError: LocalizedError {
    case missingQuestions(topic: QuizTopic)
    case missingRecentMistakes(topic: QuizTopic)
    case invalidQuestion(UUID, reason: String)
    case invalidProgressSave(topicID: String)
    case favoriteSaveFailed(drugID: String)

    var errorDescription: String? {
        switch self {
        case .missingQuestions(let topic):
            return "No hay preguntas disponibles para \(topic.title) en \(topic.subtitle)."
        case .missingRecentMistakes(let topic):
            return "No hay errores recientes para \(topic.title) en \(topic.subtitle)."
        case .invalidQuestion(_, let reason):
            return reason
        case .invalidProgressSave:
            return "No se pudo guardar el progreso de la sesion."
        case .favoriteSaveFailed:
            return "No se pudo actualizar el estado de favorito."
        }
    }
}
