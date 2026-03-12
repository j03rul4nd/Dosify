import Foundation

struct LearningSummary {
    let totalSessions: Int
    let totalCorrectAnswers: Int
    let totalIncorrectAnswers: Int
    let masteredTopics: Int

    var totalAnswers: Int {
        totalCorrectAnswers + totalIncorrectAnswers
    }

    var accuracyRate: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalAnswers)
    }

    var accuracyPercentageText: String {
        "\(Int((accuracyRate * 100).rounded()))%"
    }
}

struct TopicProgressSnapshot {
    let topic: QuizTopic
    let completedSessions: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let highestDifficulty: DifficultyLevel

    var totalAnswers: Int {
        correctAnswers + incorrectAnswers
    }

    var accuracyRate: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }

    var accuracyPercentageText: String {
        "\(Int((accuracyRate * 100).rounded()))%"
    }
}

struct LearningBadge: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
}
