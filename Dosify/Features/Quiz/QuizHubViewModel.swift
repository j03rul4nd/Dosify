import Foundation
import SwiftUI

struct QuizHubViewModel {
    var selectedSystem: StudySystem = .respiratory
    var selectedMode: QuizMode = .multipleChoice
    var selectedDifficulty: DifficultyLevel = .easy
    var selectedCollectionFilter: TopicCollectionFilter = .all
    var selectedSessionLength: QuizSessionLength = .ten
    var selectedPresentationMode: QuizPresentationMode = .practice

    var selectedTopic: QuizTopic {
        QuizTopic(
            system: selectedSystem,
            mode: selectedMode,
            difficulty: selectedDifficulty
        )
    }

    func filteredQuestions(store: DosifyStore) -> [Question] {
        store.questions(for: selectedTopic)
    }

    func selectedTopicProgress(from progressEntries: [UserProgress]) -> UserProgress? {
        progressEntries.first { $0.topicID == selectedTopic.id }
    }

    func selectedTopicAccuracyText(from progressEntries: [UserProgress]) -> String {
        guard let progress = selectedTopicProgress(from: progressEntries) else { return "0%" }
        return "\(Int((progress.accuracyRate * 100).rounded()))%"
    }

    func filteredTopics(
        store: DosifyStore,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> [QuizTopic] {
        store.topics(
            matching: selectedCollectionFilter,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    func relatedTopics(
        store: DosifyStore,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> [QuizTopic] {
        let topics = filteredTopics(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
        let systemTopics = topics.filter { $0.system == selectedSystem }
        return systemTopics.isEmpty ? topics : systemTopics
    }

    func recentMistakesCount(store: DosifyStore, questionHistories: [QuestionHistory]) -> Int {
        store.recentMistakeCount(for: selectedTopic, questionHistories: questionHistories)
    }

    func heroSubtitle(questionCount: Int) -> String {
        selectedPresentationMode == .exam
            ? "Modo examen activado: evalua retencion real sin feedback inmediato."
            : "Convierte el estudio en repaso activo con filtros precisos, progreso visible y \(questionCount) preguntas listas para lanzar."
    }

    func launchSubtitle(from progressEntries: [UserProgress]) -> String {
        selectedTopicProgress(from: progressEntries) == nil
            ? "Todavia no has practicado este tema. Buen momento para empezar."
            : "Tu progreso anterior se conserva y esta sesion sumara nuevo aprendizaje."
    }

    func makeRequest(strategy: QuizQuestionSelectionStrategy) -> QuizSessionRequest {
        QuizSessionRequest(
            topic: selectedTopic,
            strategy: strategy,
            questionLimit: selectedSessionLength.questionLimit,
            presentationMode: strategy == .recentMistakes ? .practice : selectedPresentationMode
        )
    }

    mutating func applyPendingTopic(_ topic: QuizTopic?) -> Bool {
        guard let topic else { return false }
        apply(topic: topic)
        return true
    }

    mutating func applyPendingRequest(_ request: QuizSessionRequest?) -> Bool {
        guard let request else { return false }
        apply(topic: request.topic)
        selectedSessionLength = request.questionLimit.flatMap(QuizSessionLength.init(rawValue:)) ?? .full
        selectedPresentationMode = request.presentationMode
        return true
    }

    mutating func apply(topic: QuizTopic) {
        selectedSystem = topic.system
        selectedMode = topic.mode
        selectedDifficulty = topic.difficulty
    }

    mutating func apply(draft: QuizSessionDraft) {
        apply(topic: draft.session.topic)
        selectedPresentationMode = draft.session.presentationMode
        selectedSessionLength = QuizSessionLength(rawValue: draft.session.questions.count) ?? .full
    }

    mutating func applyTopicCollectionCandidate(
        store: DosifyStore,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) {
        let candidate = filteredTopics(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        ).first

        if let candidate {
            apply(topic: candidate)
        }
    }

    var launchTint: Color {
        selectedPresentationMode == .exam ? .black : selectedSystem.tintColor
    }
}
