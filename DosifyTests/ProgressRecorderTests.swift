import Foundation
import SwiftData
import Testing
@testable import Dosify

struct ProgressRecorderTests {
    @Test
    func recordCreatesNewProgressEntry() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let recorder = ProgressRecorder()
        let result = QuizSessionResult(
            topic: QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy),
            totalQuestions: 5,
            correctAnswers: 4,
            attempts: [
                QuestionAttemptRecord(
                    questionID: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                    topicID: "respiratory-matching-easy",
                    answeredAt: .now,
                    selectedAnswer: "Budesonida",
                    wasCorrect: true
                ),
                QuestionAttemptRecord(
                    questionID: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                    topicID: "respiratory-matching-easy",
                    answeredAt: .now,
                    selectedAnswer: "Incorrecta",
                    wasCorrect: false
                )
            ],
            reviewItems: [],
            presentationMode: .practice
        )

        try recorder.record(result: result, in: context, existingEntries: [], existingHistories: [])

        let entries = try context.fetch(FetchDescriptor<UserProgress>())
        let histories = try context.fetch(FetchDescriptor<QuestionHistory>())

        #expect(entries.count == 1)
        #expect(entries.first?.topicID == result.topic.id)
        #expect(entries.first?.correctAnswers == 4)
        #expect(entries.first?.incorrectAnswers == 1)
        #expect(entries.first?.completedSessions == 1)
        #expect(entries.first?.highestDifficulty == .easy)
        #expect(histories.count == 2)
    }

    @Test
    func recordUpdatesExistingProgressEntry() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let existing = UserProgress(
            topicID: "cardiovascular-multipleChoice-medium",
            correctAnswers: 3,
            incorrectAnswers: 2,
            completedSessions: 1,
            highestDifficulty: .easy
        )
        context.insert(existing)
        try context.save()

        let recorder = ProgressRecorder()
        let result = QuizSessionResult(
            topic: QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium),
            totalQuestions: 4,
            correctAnswers: 2,
            attempts: [
                QuestionAttemptRecord(
                    questionID: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                    topicID: "cardiovascular-multipleChoice-medium",
                    answeredAt: .now,
                    selectedAnswer: "Enalapril",
                    wasCorrect: true
                )
            ],
            reviewItems: [],
            presentationMode: .practice
        )

        try recorder.record(result: result, in: context, existingEntries: [existing], existingHistories: [])

        let entries = try context.fetch(FetchDescriptor<UserProgress>())
        let updated = try #require(entries.first)

        #expect(entries.count == 1)
        #expect(updated.correctAnswers == 5)
        #expect(updated.incorrectAnswers == 4)
        #expect(updated.completedSessions == 2)
        #expect(updated.highestDifficulty == .medium)
    }

    @Test
    func recordUpdatesExistingQuestionHistory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let existingHistory = QuestionHistory(
            questionID: "30000000-0000-0000-0000-000000000001",
            topicID: "nervous-multipleChoice-hard",
            correctAttempts: 1,
            incorrectAttempts: 1,
            lastAnsweredAt: .distantPast,
            lastIncorrectAt: .distantPast
        )
        context.insert(existingHistory)
        try context.save()

        let recorder = ProgressRecorder()
        let answeredAt = Date()
        let result = QuizSessionResult(
            topic: QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard),
            totalQuestions: 1,
            correctAnswers: 1,
            attempts: [
                QuestionAttemptRecord(
                    questionID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
                    topicID: "nervous-multipleChoice-hard",
                    answeredAt: answeredAt,
                    selectedAnswer: "Diazepam",
                    wasCorrect: true
                )
            ],
            reviewItems: [],
            presentationMode: .practice
        )

        try recorder.record(
            result: result,
            in: context,
            existingEntries: [],
            existingHistories: [existingHistory]
        )

        let histories = try context.fetch(FetchDescriptor<QuestionHistory>())
        let updated = try #require(histories.first)

        #expect(histories.count == 1)
        #expect(updated.correctAttempts == 2)
        #expect(updated.incorrectAttempts == 1)
        #expect(updated.lastAnsweredAt == answeredAt)
        #expect(updated.lastIncorrectAt == .distantPast)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: UserProgress.self, QuestionHistory.self, configurations: configuration)
    }
}
