import Foundation
import OSLog
import SwiftData

struct ProgressRecorder {
    func record(
        result: QuizSessionResult,
        in modelContext: ModelContext,
        existingEntries: [UserProgress],
        existingHistories: [QuestionHistory]
    ) throws {
        let progress = existingEntries.first { $0.topicID == result.topic.id } ?? {
            let newProgress = UserProgress(topicID: result.topic.id)
            modelContext.insert(newProgress)
            return newProgress
        }()

        progress.correctAnswers += result.correctAnswers
        progress.incorrectAnswers += result.incorrectAnswers
        progress.completedSessions += 1
        progress.highestDifficulty = max(progress.highestDifficulty, result.topic.difficulty)
        progress.lastUpdatedAt = .now

        for attempt in result.attempts {
            let attemptQuestionID = attempt.questionID.uuidString
            let history = existingHistories.first { $0.questionID == attemptQuestionID } ?? {
                let newHistory = QuestionHistory(
                    questionID: attemptQuestionID,
                    topicID: attempt.topicID
                )
                modelContext.insert(newHistory)
                return newHistory
            }()

            history.lastAnsweredAt = attempt.answeredAt

            if attempt.wasCorrect {
                history.correctAttempts += 1
            } else {
                history.incorrectAttempts += 1
                history.lastIncorrectAt = attempt.answeredAt
            }
        }

        do {
            try modelContext.save()
            AppLogger.persistence.info("Progress saved for topic \(result.topic.id, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Failed to save progress for topic \(result.topic.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw QuizSessionError.invalidProgressSave(topicID: result.topic.id)
        }
    }
}
