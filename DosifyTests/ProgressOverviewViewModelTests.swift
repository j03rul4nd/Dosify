import Foundation
import Testing
@testable import Dosify

struct ProgressOverviewViewModelTests {
    @Test
    func dailyReviewPlanMarksMistakeTopicAsDue() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let topic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let question = try #require(store.questions(for: topic).first)
        let histories = [
            QuestionHistory(
                questionID: question.id.uuidString,
                topicID: topic.id,
                correctAttempts: 0,
                incorrectAttempts: 1,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        let viewModel = ProgressOverviewViewModel(
            store: store,
            progressEntries: [],
            questionHistories: histories
        )

        #expect(viewModel.dailyReviewPlan.dueTopics.contains(where: { $0.id == topic.id }))
        #expect(viewModel.primaryReviewTopic?.id == topic.id)
        #expect(viewModel.primaryRecommendation?.request.strategy == .recentMistakes)
        #expect(viewModel.primaryRecommendation?.request.questionLimit == 5)
        #expect(viewModel.primaryRecommendation?.request.launchBehavior == .autoStart)
    }

    @Test
    func overviewBuildsStrongAndWeakTopicsFromProgress() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let strongTopic = QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium)
        let weakTopic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let progress = [
            UserProgress(
                topicID: strongTopic.id,
                correctAnswers: 8,
                incorrectAnswers: 1,
                completedSessions: 3,
                highestDifficulty: .medium
            ),
            UserProgress(
                topicID: weakTopic.id,
                correctAnswers: 1,
                incorrectAnswers: 4,
                completedSessions: 1,
                highestDifficulty: .easy
            )
        ]

        let viewModel = ProgressOverviewViewModel(
            store: store,
            progressEntries: progress,
            questionHistories: []
        )

        #expect(viewModel.strongestTopics.first?.topic.id == strongTopic.id)
        #expect(viewModel.weakestTopics.first?.topic.id == weakTopic.id)
    }
}
