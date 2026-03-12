import Foundation
import SwiftData

@Model
final class QuestionHistory {
    @Attribute(.unique) var questionID: String
    var topicID: String
    var correctAttempts: Int
    var incorrectAttempts: Int
    var lastAnsweredAt: Date
    var lastIncorrectAt: Date?

    init(
        questionID: String,
        topicID: String,
        correctAttempts: Int = 0,
        incorrectAttempts: Int = 0,
        lastAnsweredAt: Date = .now,
        lastIncorrectAt: Date? = nil
    ) {
        self.questionID = questionID
        self.topicID = topicID
        self.correctAttempts = correctAttempts
        self.incorrectAttempts = incorrectAttempts
        self.lastAnsweredAt = lastAnsweredAt
        self.lastIncorrectAt = lastIncorrectAt
    }

    var totalAttempts: Int {
        correctAttempts + incorrectAttempts
    }
}
