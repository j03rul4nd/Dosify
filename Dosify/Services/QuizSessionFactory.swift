import Foundation
import OSLog

struct QuizSessionFactory {
    private let analyticsService: StudyAnalyticsService

    init(analyticsService: StudyAnalyticsService = StudyAnalyticsService()) {
        self.analyticsService = analyticsService
    }

    func makeSession(
        request: QuizSessionRequest,
        catalog: CatalogSnapshot,
        questionHistories: [QuestionHistory]
    ) -> Result<QuizSession, QuizSessionError> {
        let questions = sessionQuestions(for: request, in: catalog, questionHistories: questionHistories)

        if request.strategy == .recentMistakes && questions.isEmpty {
            let error = QuizSessionError.missingRecentMistakes(topic: request.topic)
            AppLogger.quiz.error("Quiz session creation failed: \(error.localizedDescription, privacy: .public)")
            return .failure(error)
        }

        do {
            return .success(
                try QuizSession(
                    topic: request.topic,
                    questions: questions,
                    questionLimit: request.questionLimit,
                    presentationMode: request.presentationMode
                )
            )
        } catch let error as QuizSessionError {
            AppLogger.quiz.error("Quiz session creation failed: \(error.localizedDescription, privacy: .public)")
            return .failure(error)
        } catch {
            AppLogger.quiz.error("Unexpected session error for topic \(request.topic.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return .failure(.missingQuestions(topic: request.topic))
        }
    }

    private func sessionQuestions(
        for request: QuizSessionRequest,
        in catalog: CatalogSnapshot,
        questionHistories: [QuestionHistory]
    ) -> [Question] {
        switch request.strategy {
        case .standard:
            return catalog.questions(for: request.topic)
        case .recentMistakes:
            return analyticsService.recentMistakeQuestions(
                for: request.topic,
                in: catalog,
                questionHistories: questionHistories,
                limit: request.questionLimit
            )
        }
    }
}

struct QuizDraftStore {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "dosify.quiz.sessionDraft"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ draft: QuizSessionDraft) {
        do {
            let data = try encoder.encode(draft)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.persistence.error("Failed to persist quiz draft: \(error.localizedDescription, privacy: .public)")
        }
    }

    func load() -> QuizSessionDraft? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }

        do {
            return try decoder.decode(QuizSessionDraft.self, from: data)
        } catch {
            AppLogger.persistence.error("Failed to restore quiz draft: \(error.localizedDescription, privacy: .public)")
            clear()
            return nil
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
