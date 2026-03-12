import Foundation
import SwiftData

@Model
final class UserProgress {
    @Attribute(.unique) var topicID: String
    var correctAnswers: Int
    var incorrectAnswers: Int
    var completedSessions: Int
    var highestDifficultyRawValue: String
    var lastUpdatedAt: Date

    init(
        topicID: String,
        correctAnswers: Int = 0,
        incorrectAnswers: Int = 0,
        completedSessions: Int = 0,
        highestDifficulty: DifficultyLevel = .easy,
        lastUpdatedAt: Date = .now
    ) {
        self.topicID = topicID
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.completedSessions = completedSessions
        self.highestDifficultyRawValue = highestDifficulty.rawValue
        self.lastUpdatedAt = lastUpdatedAt
    }

    var highestDifficulty: DifficultyLevel {
        get { DifficultyLevel(rawValue: highestDifficultyRawValue) ?? .easy }
        set { highestDifficultyRawValue = newValue.rawValue }
    }

    var totalAnswers: Int {
        correctAnswers + incorrectAnswers
    }

    var accuracyRate: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
}
