import Combine
import Foundation
import OSLog

final class DosifyStore: ObservableObject {
    @Published private(set) var loadIssues: [CatalogIssue] = []
    @Published var subscriptionState: SubscriptionState = .freeWithAds

    private let loader: SeedDataLoader
    private let analyticsService: StudyAnalyticsService
    private let sessionFactory: QuizSessionFactory
    private var catalog: CatalogSnapshot = .empty

    init(
        loader: SeedDataLoader = SeedDataLoader(),
        analyticsService: StudyAnalyticsService = StudyAnalyticsService(),
        sessionFactory: QuizSessionFactory? = nil
    ) {
        self.loader = loader
        self.analyticsService = analyticsService
        self.sessionFactory = sessionFactory ?? QuizSessionFactory(analyticsService: analyticsService)
        reloadCatalog()
    }

    var systems: [StudySystem] {
        catalog.availableSystems
    }

    func drugs(for system: StudySystem) -> [Drug] {
        catalog.drugs(for: system)
    }

    func questions(for system: StudySystem, mode: QuizMode, difficulty: DifficultyLevel) -> [Question] {
        questions(for: QuizTopic(system: system, mode: mode, difficulty: difficulty))
    }

    func questions(for topic: QuizTopic) -> [Question] {
        catalog.questions(for: topic)
    }

    func topic(
        system: StudySystem,
        mode: QuizMode,
        difficulty: DifficultyLevel
    ) -> QuizTopic {
        QuizTopic(system: system, mode: mode, difficulty: difficulty)
    }

    func makeSession(
        request: QuizSessionRequest,
        questionHistories: [QuestionHistory]
    ) -> Result<QuizSession, QuizSessionError> {
        sessionFactory.makeSession(
            request: request,
            catalog: catalog,
            questionHistories: questionHistories
        )
    }

    func reloadCatalog() {
        let result = loader.loadCatalog()
        catalog = CatalogSnapshot(drugs: result.drugs, questions: result.questions)
        loadIssues = result.issues

        if loadIssues.isEmpty {
            AppLogger.catalog.info("Catalog loaded with \(result.drugs.count, privacy: .public) drugs and \(result.questions.count, privacy: .public) questions")
        } else {
            AppLogger.catalog.warning("Catalog loaded with \(self.loadIssues.count, privacy: .public) issues")
        }
    }

    func availableTopics() -> [QuizTopic] {
        analyticsService.availableTopics(in: catalog)
    }

    func topics(
        matching filter: TopicCollectionFilter,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> [QuizTopic] {
        analyticsService.topics(
            matching: filter,
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    func practiceTopic(for drug: Drug) -> QuizTopic? {
        analyticsService.practiceTopic(for: drug, in: catalog)
    }

    func favoriteDrugIDs(from favorites: [FavoriteDrug]) -> Set<String> {
        Set(favorites.map(\.drugID))
    }

    func isFavorite(drug: Drug, favorites: [FavoriteDrug]) -> Bool {
        favoriteDrugIDs(from: favorites).contains(drug.id.uuidString)
    }

    func recentMistakeCount(for topic: QuizTopic, questionHistories: [QuestionHistory], since: Date = .distantPast) -> Int {
        analyticsService.recentMistakeCount(for: topic, questionHistories: questionHistories, since: since)
    }

    func recentMistakeQuestions(for topic: QuizTopic, questionHistories: [QuestionHistory], limit: Int? = nil) -> [Question] {
        analyticsService.recentMistakeQuestions(
            for: topic,
            in: catalog,
            questionHistories: questionHistories,
            limit: limit
        )
    }

    func learningSummary(from progressEntries: [UserProgress]) -> LearningSummary {
        analyticsService.learningSummary(from: progressEntries)
    }

    func topicProgressSnapshot(for topic: QuizTopic, from progressEntries: [UserProgress]) -> TopicProgressSnapshot? {
        analyticsService.topicProgressSnapshot(for: topic, from: progressEntries)
    }

    func recommendedTopic(from progressEntries: [UserProgress]) -> QuizTopic? {
        analyticsService.recommendedTopic(from: progressEntries, in: catalog)
    }

    func badges(from progressEntries: [UserProgress]) -> [LearningBadge] {
        analyticsService.badges(from: progressEntries)
    }

    func weakestTopics(from progressEntries: [UserProgress], limit: Int = 3) -> [TopicProgressSnapshot] {
        analyticsService.weakestTopics(in: catalog, progressEntries: progressEntries, limit: limit)
    }

    func strongestTopics(from progressEntries: [UserProgress], limit: Int = 3) -> [TopicProgressSnapshot] {
        analyticsService.strongestTopics(in: catalog, progressEntries: progressEntries, limit: limit)
    }

    func dailyReviewPlan(
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory],
        now: Date = .now
    ) -> DailyReviewPlan {
        analyticsService.dailyReviewPlan(
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: questionHistories,
            now: now
        )
    }

    func followUpRecommendation(after result: QuizSessionResult) -> ReviewRecommendation? {
        let score = Double(result.correctAnswers) / Double(max(result.totalQuestions, 1))

        if result.incorrectAnswers > 0 {
            return ReviewRecommendation(
                request: QuizSessionRequest(
                    topic: result.topic,
                    strategy: .recentMistakes,
                    questionLimit: min(result.incorrectAnswers, 5),
                    presentationMode: .practice,
                    launchBehavior: .autoStart
                ),
                title: "Corrige tus fallos ahora",
                subtitle: "Aprovecha que los errores estan frescos con un repaso corto centrado en lo que acabas de fallar."
            )
        }

        if score >= 0.8, let nextTopic = nextDifficultyTopic(after: result.topic) {
            return ReviewRecommendation(
                request: QuizSessionRequest(
                    topic: nextTopic,
                    strategy: .standard,
                    questionLimit: 10,
                    presentationMode: .practice,
                    launchBehavior: .configureOnly
                ),
                title: "Sube un nivel",
                subtitle: "Has consolidado bien este bloque. El siguiente paso natural es practicar la misma ruta con mas dificultad."
            )
        }

        return ReviewRecommendation(
            request: QuizSessionRequest(
                topic: result.topic,
                strategy: .standard,
                questionLimit: 10,
                presentationMode: .practice,
                launchBehavior: .configureOnly
            ),
            title: "Haz otra pasada breve",
            subtitle: "Una sesion adicional del mismo tema puede convertir este resultado en memoria mas estable."
        )
    }

    func focusTopic(
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> QuizTopic? {
        analyticsService.focusTopic(
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    private func nextDifficultyTopic(after topic: QuizTopic) -> QuizTopic? {
        availableTopics()
            .filter { $0.system == topic.system && $0.mode == topic.mode && $0.difficulty > topic.difficulty }
            .sorted { $0.difficulty < $1.difficulty }
            .first
    }
}
