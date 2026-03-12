import Foundation
import Testing
@testable import Dosify

struct HomeDashboardViewModelTests {
    @Test
    func firstLaunchExperienceUsesWelcomeNarrative() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let viewModel = HomeDashboardViewModel(
            store: store,
            progressEntries: [],
            questionHistories: [],
            favoriteDrugs: []
        )

        #expect(viewModel.isFirstLaunchExperience)
        #expect(viewModel.heroEyebrow == "Bienvenido a Dosify")
        #expect(viewModel.primaryActionTitle == "Empezar a estudiar")
        #expect(viewModel.primaryActionTopic != nil)
    }

    @Test
    func returningExperiencePrioritizesRecoveryNarrative() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let focusTopic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let progressEntries = [
            UserProgress(
                topicID: focusTopic.id,
                correctAnswers: 2,
                incorrectAnswers: 3,
                completedSessions: 1,
                highestDifficulty: .easy
            )
        ]
        let histories = [
            QuestionHistory(
                questionID: UUID().uuidString,
                topicID: focusTopic.id,
                correctAttempts: 0,
                incorrectAttempts: 2,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]
        let favorites = [FavoriteDrug(drugID: UUID().uuidString)]

        let viewModel = HomeDashboardViewModel(
            store: store,
            progressEntries: progressEntries,
            questionHistories: histories,
            favoriteDrugs: favorites
        )

        #expect(!viewModel.isFirstLaunchExperience)
        #expect(viewModel.heroEyebrow == "Tu centro de estudio")
        #expect(viewModel.heroSubtitle.contains("errores recientes"))
        #expect(viewModel.focusTopic?.id == focusTopic.id)
        #expect(viewModel.focusSupportingText.contains("1 favoritos guardados"))
    }

    @Test
    func homeUsesDailyReviewRecommendationAsPrimaryReviewAction() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let topic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let question = try #require(store.questions(for: topic).first)

        let viewModel = HomeDashboardViewModel(
            store: store,
            progressEntries: [],
            questionHistories: [
                QuestionHistory(
                    questionID: question.id.uuidString,
                    topicID: topic.id,
                    correctAttempts: 0,
                    incorrectAttempts: 1,
                    lastAnsweredAt: .now,
                    lastIncorrectAt: .now
                )
            ],
            favoriteDrugs: []
        )

        #expect(viewModel.reviewTopicForToday?.id == topic.id)
        #expect(viewModel.reviewRecommendationForToday?.request.strategy == .recentMistakes)
        #expect(viewModel.reviewRecommendationForToday?.request.launchBehavior == .autoStart)
    }
}
