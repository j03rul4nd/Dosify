import Combine
import Foundation

@MainActor
final class QuizSessionViewModel: ObservableObject {
    @Published private(set) var session: QuizSession
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var correctAnswers: Int = 0
    @Published private(set) var hasAnsweredCurrentQuestion: Bool = false
    @Published private(set) var submittedAnswer: String?
    @Published var selectedAnswer: String?
    @Published private(set) var attempts: [QuestionAttemptRecord] = []

    init(session: QuizSession) {
        self.session = session
    }

    init(draft: QuizSessionDraft) {
        self.session = draft.session
        self.currentIndex = draft.currentIndex
        self.correctAnswers = draft.correctAnswers
        self.hasAnsweredCurrentQuestion = draft.hasAnsweredCurrentQuestion
        self.submittedAnswer = draft.submittedAnswer
        self.selectedAnswer = draft.selectedAnswer
        self.attempts = draft.attempts
    }

    var currentQuestion: Question {
        session.questions[currentIndex]
    }

    var topic: QuizTopic {
        session.topic
    }

    var progressLabel: String {
        "Pregunta \(currentIndex + 1) de \(session.questions.count)"
    }

    var sessionProgress: Double {
        guard !session.questions.isEmpty else { return 0 }
        return Double(currentIndex + (isCompleted ? 0 : 1)) / Double(session.questions.count)
    }

    var isAnswerSubmitted: Bool {
        hasAnsweredCurrentQuestion
    }

    var hasNextQuestion: Bool {
        currentIndex < session.questions.count - 1
    }

    var isCompleted: Bool {
        currentIndex >= session.questions.count
    }

    var canSubmitAnswer: Bool {
        selectedAnswer != nil && !hasAnsweredCurrentQuestion
    }

    var shouldRevealImmediateFeedback: Bool {
        session.presentationMode == .practice
    }

    func submitAnswer() {
        guard !hasAnsweredCurrentQuestion else { return }
        guard let selectedAnswer else { return }

        let wasCorrect = selectedAnswer == currentQuestion.correctAnswer

        if shouldRevealImmediateFeedback {
            submittedAnswer = selectedAnswer
        }

        hasAnsweredCurrentQuestion = true

        if wasCorrect {
            correctAnswers += 1
        }

        attempts.append(
            QuestionAttemptRecord(
                questionID: currentQuestion.id,
                topicID: topic.id,
                answeredAt: .now,
                selectedAnswer: selectedAnswer,
                wasCorrect: wasCorrect
            )
        )
    }

    func advance() {
        guard isAnswerSubmitted else { return }

        selectedAnswer = nil
        submittedAnswer = nil
        hasAnsweredCurrentQuestion = false
        currentIndex += 1
    }

    func finishResult() -> QuizSessionResult {
        let reviewLookup = Dictionary(uniqueKeysWithValues: session.questions.map { ($0.id, $0) })
        let reviewItems = attempts.compactMap { attempt -> QuestionReviewItem? in
            guard let question = reviewLookup[attempt.questionID] else { return nil }
            return QuestionReviewItem(
                id: question.id,
                prompt: question.prompt,
                correctAnswer: question.correctAnswer,
                selectedAnswer: attempt.selectedAnswer,
                explanation: question.explanation,
                wasCorrect: attempt.wasCorrect
            )
        }

        return QuizSessionResult(
            topic: topic,
            totalQuestions: session.questions.count,
            correctAnswers: correctAnswers,
            attempts: attempts,
            reviewItems: reviewItems,
            presentationMode: session.presentationMode
        )
    }

    func answerState(for option: String) -> QuizAnswerState {
        guard let submittedAnswer else { return .idle }

        if option == currentQuestion.correctAnswer {
            return .correct
        }

        if option == submittedAnswer {
            return .incorrect
        }

        return .idle
    }

    func makeDraft() -> QuizSessionDraft {
        QuizSessionDraft(
            session: session,
            currentIndex: currentIndex,
            correctAnswers: correctAnswers,
            hasAnsweredCurrentQuestion: hasAnsweredCurrentQuestion,
            submittedAnswer: submittedAnswer,
            selectedAnswer: selectedAnswer,
            attempts: attempts
        )
    }
}

enum QuizAnswerState {
    case idle
    case correct
    case incorrect
}
