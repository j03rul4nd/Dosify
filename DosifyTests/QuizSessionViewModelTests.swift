import Foundation
import Testing
@testable import Dosify

@MainActor
struct QuizSessionViewModelTests {
    @Test
    func practiceModeRevealsImmediateFeedback() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .practice
        )
        let viewModel = QuizSessionViewModel(session: session)

        viewModel.selectedAnswer = "Salbutamol"
        viewModel.submitAnswer()

        #expect(viewModel.submittedAnswer == "Salbutamol")
        #expect(viewModel.correctAnswers == 1)
        #expect(viewModel.shouldRevealImmediateFeedback)
        #expect(viewModel.isAnswerSubmitted)
    }

    @Test
    func examModeDoesNotRevealImmediateFeedback() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .exam
        )
        let viewModel = QuizSessionViewModel(session: session)

        viewModel.selectedAnswer = "Salbutamol"
        viewModel.submitAnswer()

        #expect(viewModel.submittedAnswer == nil)
        #expect(viewModel.correctAnswers == 1)
        #expect(!viewModel.shouldRevealImmediateFeedback)
        #expect(viewModel.isAnswerSubmitted)
    }

    @Test
    func examModeAllowsAdvanceWithoutImmediateFeedback() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion(), makeQuestion(id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!)],
            questionLimit: nil,
            presentationMode: .exam
        )
        let viewModel = QuizSessionViewModel(session: session)

        viewModel.selectedAnswer = "Salbutamol"
        viewModel.submitAnswer()
        viewModel.advance()

        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.selectedAnswer == nil)
        #expect(!viewModel.isAnswerSubmitted)
    }

    @Test
    func submitAnswerIgnoresRepeatedSubmissionForSameQuestion() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .exam
        )
        let viewModel = QuizSessionViewModel(session: session)

        viewModel.selectedAnswer = "Salbutamol"
        viewModel.submitAnswer()
        viewModel.submitAnswer()

        #expect(viewModel.correctAnswers == 1)
        #expect(viewModel.attempts.count == 1)
    }

    @Test
    func draftRestoresOngoingSessionState() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .practice
        )
        let original = QuizSessionViewModel(session: session)

        original.selectedAnswer = "Salbutamol"
        original.submitAnswer()

        let restored = QuizSessionViewModel(draft: original.makeDraft())

        #expect(restored.correctAnswers == 1)
        #expect(restored.isAnswerSubmitted)
        #expect(restored.selectedAnswer == "Salbutamol")
        #expect(restored.attempts.count == 1)
    }

    @Test
    func finishResultBuildsReviewItems() throws {
        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .exam
        )
        let viewModel = QuizSessionViewModel(session: session)

        viewModel.selectedAnswer = "Budesonida"
        viewModel.submitAnswer()

        let result = viewModel.finishResult()

        #expect(result.reviewItems.count == 1)
        #expect(result.reviewItems.first?.selectedAnswer == "Budesonida")
        #expect(result.reviewItems.first?.correctAnswer == "Salbutamol")
        #expect(result.presentationMode == .exam)
    }

    @Test
    func draftStoreRoundTripsPersistedDraft() throws {
        let suiteName = "QuizDraftStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let session = try QuizSession(
            topic: QuizTopic(system: .respiratory, mode: .multipleChoice, difficulty: .easy),
            questions: [makeQuestion()],
            questionLimit: nil,
            presentationMode: .practice
        )
        let draft = QuizSessionDraft(
            session: session,
            currentIndex: 0,
            correctAnswers: 1,
            hasAnsweredCurrentQuestion: true,
            submittedAnswer: "Salbutamol",
            selectedAnswer: "Salbutamol",
            attempts: [
                QuestionAttemptRecord(
                    questionID: session.questions[0].id,
                    topicID: session.topic.id,
                    answeredAt: .now,
                    selectedAnswer: "Salbutamol",
                    wasCorrect: true
                )
            ]
        )

        let store = QuizDraftStore(userDefaults: defaults)
        store.save(draft)
        let restored = try #require(store.load())

        #expect(restored.session.topic == draft.session.topic)
        #expect(restored.correctAnswers == draft.correctAnswers)
        #expect(restored.attempts == draft.attempts)

        store.clear()
        #expect(store.load() == nil)
    }

    @Test
    func draftStoreClearsCorruptedPayload() throws {
        let suiteName = "QuizDraftStoreCorruption.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(Data("invalid-json".utf8), forKey: "dosify.quiz.sessionDraft")

        let store = QuizDraftStore(userDefaults: defaults)

        #expect(store.load() == nil)
        #expect(defaults.data(forKey: "dosify.quiz.sessionDraft") == nil)
    }

    private func makeQuestion(id: UUID = UUID()) -> Question {
        Question(
            id: id,
            prompt: "Que farmaco se usa como broncodilatador de accion rapida?",
            mode: .multipleChoice,
            difficulty: .easy,
            system: .respiratory,
            category: .emergencySupport,
            correctAnswer: "Salbutamol",
            options: ["Budesonida", "Salbutamol", "Diazepam"],
            explanation: "Salbutamol se usa en broncoespasmo."
        )
    }
}
