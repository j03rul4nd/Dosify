import Foundation
import Testing
@testable import Dosify

struct QuizHubViewModelTests {
    @Test
    func makeRequestUsesCurrentSelection() {
        var viewModel = QuizHubViewModel()
        viewModel.selectedSystem = .cardiovascular
        viewModel.selectedMode = .multipleChoice
        viewModel.selectedDifficulty = .medium
        viewModel.selectedSessionLength = .twenty
        viewModel.selectedPresentationMode = .exam

        let request = viewModel.makeRequest(strategy: .standard)

        #expect(request.topic.id == "cardiovascular-multipleChoice-medium")
        #expect(request.questionLimit == 20)
        #expect(request.presentationMode == .exam)
    }

    @Test
    func mistakeReviewAlwaysForcesPracticeMode() {
        var viewModel = QuizHubViewModel()
        viewModel.selectedPresentationMode = .exam

        let request = viewModel.makeRequest(strategy: .recentMistakes)

        #expect(request.presentationMode == .practice)
    }

    @Test
    func applyPendingTopicUpdatesSelection() {
        var viewModel = QuizHubViewModel()
        let topic = QuizTopic(system: .nervous, mode: .matching, difficulty: .hard)

        let didApply = viewModel.applyPendingTopic(topic)

        #expect(didApply)
        #expect(viewModel.selectedTopic.id == topic.id)
    }

    @Test
    func applyPendingRequestUpdatesSessionConfiguration() {
        var viewModel = QuizHubViewModel()
        let request = QuizSessionRequest(
            topic: QuizTopic(system: .cardiovascular, mode: .multipleChoice, difficulty: .medium),
            strategy: .recentMistakes,
            questionLimit: 5,
            presentationMode: .practice,
            launchBehavior: .autoStart
        )

        let didApply = viewModel.applyPendingRequest(request)

        #expect(didApply)
        #expect(viewModel.selectedTopic.id == request.topic.id)
        #expect(viewModel.selectedSessionLength == .five)
        #expect(viewModel.selectedPresentationMode == .practice)
    }

    @Test
    func applyDraftRestoresTopicAndPresentationMode() throws {
        var viewModel = QuizHubViewModel()
        let session = try QuizSession(
            topic: QuizTopic(system: .nervous, mode: .matching, difficulty: .hard),
            questions: [
                Question(
                    id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
                    prompt: "Relaciona un farmaco del sistema nervioso.",
                    mode: .matching,
                    difficulty: .hard,
                    system: .nervous,
                    category: .chronicControl,
                    correctAnswer: "Control de crisis",
                    options: ["Control de crisis", "Broncoespasmo"],
                    explanation: "Se enfoca en reforzar memoria del sistema nervioso."
                )
            ],
            questionLimit: nil,
            presentationMode: .exam
        )

        viewModel.apply(draft: QuizSessionDraft(session: session))

        #expect(viewModel.selectedTopic.id == session.topic.id)
        #expect(viewModel.selectedPresentationMode == .exam)
        #expect(viewModel.selectedSessionLength == .five || viewModel.selectedSessionLength == .full)
    }

    @Test
    func applyTopicCollectionCandidateSelectsFirstTopicInCollection() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        var viewModel = QuizHubViewModel()
        viewModel.selectedCollectionFilter = .failedRecently

        let targetTopic = QuizTopic(system: .nervous, mode: .multipleChoice, difficulty: .hard)
        let targetQuestion = try #require(store.questions(for: targetTopic).first)
        let histories = [
            QuestionHistory(
                questionID: targetQuestion.id.uuidString,
                topicID: targetTopic.id,
                correctAttempts: 0,
                incorrectAttempts: 1,
                lastAnsweredAt: .now,
                lastIncorrectAt: .now
            )
        ]

        viewModel.applyTopicCollectionCandidate(
            store: store,
            progressEntries: [],
            questionHistories: histories
        )

        #expect(viewModel.selectedTopic.id == targetTopic.id)
    }
}
