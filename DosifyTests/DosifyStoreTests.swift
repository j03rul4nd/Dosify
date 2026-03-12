import Foundation
import Testing
@testable import Dosify

struct DosifyStoreTests {
    @Test
    func topicsFilterReturnsExpectedBuckets() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let respiratoryTopic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let cardiovascularTopic = QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium)
        let nervousTopic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)

        let progressEntries = [
            UserProgress(
                topicID: cardiovascularTopic.id,
                correctAnswers: 8,
                incorrectAnswers: 1,
                completedSessions: 3,
                highestDifficulty: .medium
            ),
            UserProgress(
                topicID: nervousTopic.id,
                correctAnswers: 2,
                incorrectAnswers: 4,
                completedSessions: 1,
                highestDifficulty: .easy
            )
        ]

        let histories = [
            QuestionHistory(
                questionID: UUID().uuidString,
                topicID: nervousTopic.id,
                correctAttempts: 0,
                incorrectAttempts: 2,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        let unstarted = store.topics(matching: .unstarted, progressEntries: progressEntries, questionHistories: histories)
        let mastered = store.topics(matching: .mastered, progressEntries: progressEntries, questionHistories: histories)
        let needsReview = store.topics(matching: .needsReview, progressEntries: progressEntries, questionHistories: histories)
        let failedRecently = store.topics(matching: .failedRecently, progressEntries: progressEntries, questionHistories: histories)

        #expect(unstarted.contains(respiratoryTopic))
        #expect(mastered.contains(cardiovascularTopic))
        #expect(needsReview.contains(nervousTopic))
        #expect(failedRecently.contains(nervousTopic))
    }

    @Test
    func makeSessionForRecentMistakesFailsWithoutHistory() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let topic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let request = QuizSessionRequest(
            topic: topic,
            strategy: .recentMistakes,
            questionLimit: 5,
            presentationMode: .practice
        )

        let result = store.makeSession(request: request, questionHistories: [])

        switch result {
        case .success:
            Issue.record("Expected recent mistakes session to fail without history")
        case .failure(let error):
            #expect(error.localizedDescription.contains("No hay errores recientes"))
        }
    }

    @Test
    func makeSessionForRecentMistakesUsesMostRecentFailedQuestions() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let topic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let availableQuestions = store.questions(for: topic)
        let firstQuestion = try #require(availableQuestions.first)

        let request = QuizSessionRequest(
            topic: topic,
            strategy: .recentMistakes,
            questionLimit: 1,
            presentationMode: .practice
        )
        let histories = [
            QuestionHistory(
                questionID: firstQuestion.id.uuidString,
                topicID: topic.id,
                correctAttempts: 0,
                incorrectAttempts: 1,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        let result = store.makeSession(request: request, questionHistories: histories)

        switch result {
        case .success(let session):
            #expect(session.questions.count == 1)
            #expect(session.questions.first?.id == firstQuestion.id)
        case .failure(let error):
            Issue.record("Expected session to be created, got error: \(error.localizedDescription)")
        }
    }

    @Test
    func followUpRecommendationPrefersMistakeRecoveryWhenThereAreErrors() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let result = QuizSessionResult(
            topic: QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy),
            totalQuestions: 5,
            correctAnswers: 3,
            attempts: [],
            reviewItems: [],
            presentationMode: .practice
        )

        let recommendation = store.followUpRecommendation(after: result)

        #expect(recommendation?.request.strategy == .recentMistakes)
        #expect(recommendation?.request.launchBehavior == .autoStart)
    }

    @Test
    func followUpRecommendationSuggestsHigherDifficultyAfterStrongResult() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let result = QuizSessionResult(
            topic: QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .easy),
            totalQuestions: 5,
            correctAnswers: 5,
            attempts: [],
            reviewItems: [],
            presentationMode: .practice
        )

        let recommendation = store.followUpRecommendation(after: result)

        #expect(recommendation?.request.topic.difficulty == .medium)
        #expect(recommendation?.request.strategy == .standard)
    }
}
