import Foundation
import Testing
@testable import Dosify

struct StudyAnalyticsServiceTests {
    private let analytics = StudyAnalyticsService()

    @Test
    func recommendedTopicPrefersUnstartedTopicFirst() {
        let startedTopic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let progressEntries = [
            UserProgress(
                topicID: startedTopic.id,
                correctAnswers: 2,
                incorrectAnswers: 1,
                completedSessions: 1,
                highestDifficulty: .easy
            )
        ]

        let recommendation = analytics.recommendedTopic(from: progressEntries, in: makeCatalogSnapshot())

        #expect(recommendation != nil)
        #expect(recommendation?.id == "cardiovascular-multipleChoice-medium")
    }

    @Test
    func topicsFilterReturnsExpectedBuckets() {
        let respiratoryTopic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let cardiovascularTopic = QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium)
        let nervousTopic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let catalog = makeCatalogSnapshot()

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
                questionID: catalog.questions(for: nervousTopic).first!.id.uuidString,
                topicID: nervousTopic.id,
                correctAttempts: 0,
                incorrectAttempts: 2,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        let unstarted = analytics.topics(matching: .unstarted, in: catalog, progressEntries: progressEntries, questionHistories: histories)
        let mastered = analytics.topics(matching: .mastered, in: catalog, progressEntries: progressEntries, questionHistories: histories)
        let needsReview = analytics.topics(matching: .needsReview, in: catalog, progressEntries: progressEntries, questionHistories: histories)
        let failedRecently = analytics.topics(matching: .failedRecently, in: catalog, progressEntries: progressEntries, questionHistories: histories)

        #expect(unstarted.contains(respiratoryTopic))
        #expect(mastered.contains(cardiovascularTopic))
        #expect(needsReview.contains(nervousTopic))
        #expect(failedRecently.contains(nervousTopic))
    }

    @Test
    func recentMistakeQuestionsReturnMostRecentFirst() {
        let catalog = makeCatalogSnapshot()
        let topic = QuizTopic(system: .respiratory, mode: .matching, difficulty: .easy)
        let matchingQuestions = catalog.questions(for: topic)
        #expect(matchingQuestions.count >= 2)

        let older = QuestionHistory(
            questionID: matchingQuestions[0].id.uuidString,
            topicID: topic.id,
            correctAttempts: 0,
            incorrectAttempts: 1,
            lastAnsweredAt: .now.addingTimeInterval(-300),
            lastIncorrectAt: .now.addingTimeInterval(-300)
        )
        let newer = QuestionHistory(
            questionID: matchingQuestions[1].id.uuidString,
            topicID: topic.id,
            correctAttempts: 0,
            incorrectAttempts: 1,
            lastAnsweredAt: .now,
            lastIncorrectAt: .now
        )

        let questions = analytics.recentMistakeQuestions(
            for: topic,
            in: catalog,
            questionHistories: [older, newer],
            limit: 1
        )

        #expect(questions.count == 1)
        #expect(questions.first?.id == matchingQuestions[1].id)
    }

    @Test
    func focusTopicPrefersRecentMistakesOverGeneralRecommendation() {
        let catalog = makeCatalogSnapshot()
        let topic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let histories = [
            QuestionHistory(
                questionID: catalog.questions(for: topic).first!.id.uuidString,
                topicID: topic.id,
                correctAttempts: 0,
                incorrectAttempts: 1,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        let focusTopic = analytics.focusTopic(
            in: catalog,
            progressEntries: [],
            questionHistories: histories
        )

        #expect(focusTopic?.id == topic.id)
    }

    @Test
    func dailyReviewPlanIncludesStaleWeakTopic() {
        let catalog = makeCatalogSnapshot()
        let topic = QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium)
        let staleDate = Date().addingTimeInterval(-(60 * 60 * 24 * 5))
        let progressEntries = [
            UserProgress(
                topicID: topic.id,
                correctAnswers: 2,
                incorrectAnswers: 2,
                completedSessions: 1,
                highestDifficulty: .medium,
                lastUpdatedAt: staleDate
            )
        ]

        let plan = analytics.dailyReviewPlan(
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: [],
            now: .now
        )

        #expect(plan.dueTopics.contains(where: { $0.id == topic.id }))
    }

    private func makeCatalogSnapshot() -> CatalogSnapshot {
        let questions = [
            Question(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
                prompt: "Relaciona salbutamol con su uso.",
                mode: .matching,
                difficulty: .easy,
                system: .respiratory,
                category: .emergencySupport,
                correctAnswer: "Broncoespasmo agudo",
                options: ["Broncoespasmo agudo", "Epilepsia"],
                explanation: "Actua rapido en vias respiratorias."
            ),
            Question(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!,
                prompt: "Que farmaco cardiovascular usar?",
                mode: .multipleChoice,
                difficulty: .medium,
                system: .cardiovascular,
                category: .chronicControl,
                correctAnswer: "Enalapril",
                options: ["Enalapril", "Salbutamol", "Diazepam"],
                explanation: "Enalapril se usa en control cardiovascular."
            ),
            Question(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000003")!,
                prompt: "Que farmaco del sistema nervioso encaja mejor?",
                mode: .multipleChoice,
                difficulty: .hard,
                system: .nervous,
                category: .chronicControl,
                correctAnswer: "Diazepam",
                options: ["Diazepam", "Enalapril", "Salbutamol"],
                explanation: "Diazepam afecta al sistema nervioso."
            )
        ]

        let drugs = [
            Drug(
                id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
                name: "Salbutamol",
                system: .respiratory,
                category: .emergencySupport,
                summary: "Broncodilatador rapido.",
                mechanism: "Activa receptores beta.",
                uses: ["Broncoespasmo agudo"],
                notes: ["Uso de rescate"]
            )
        ]

        return CatalogSnapshot(drugs: drugs, questions: questions)
    }
}
