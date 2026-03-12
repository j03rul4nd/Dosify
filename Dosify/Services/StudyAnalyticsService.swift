import Foundation

struct StudyAnalyticsService {
    private let staleTopicThreshold: TimeInterval = 60 * 60 * 24 * 2

    func availableTopics(in catalog: CatalogSnapshot) -> [QuizTopic] {
        Dictionary(grouping: catalog.questions, by: \.topic)
            .keys
            .sorted(by: topicSort)
    }

    func topics(
        matching filter: TopicCollectionFilter,
        in catalog: CatalogSnapshot,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> [QuizTopic] {
        let topics = availableTopics(in: catalog)

        switch filter {
        case .all:
            return topics
        case .unstarted:
            return topics.filter { topicProgressSnapshot(for: $0, from: progressEntries) == nil }
        case .needsReview:
            return topics.filter {
                guard let snapshot = topicProgressSnapshot(for: $0, from: progressEntries) else { return false }
                return snapshot.accuracyRate < 0.7 || snapshot.highestDifficulty < .medium
            }
        case .mastered:
            return topics.filter {
                guard let snapshot = topicProgressSnapshot(for: $0, from: progressEntries) else { return false }
                return snapshot.accuracyRate >= 0.8 && snapshot.completedSessions >= 2
            }
        case .failedRecently:
            return topics.filter { recentMistakeCount(for: $0, questionHistories: questionHistories) > 0 }
        }
    }

    func practiceTopic(for drug: Drug, in catalog: CatalogSnapshot) -> QuizTopic? {
        availableTopics(in: catalog)
            .filter { $0.system == drug.system }
            .sorted(by: topicSort)
            .first
    }

    func recentMistakeCount(
        for topic: QuizTopic,
        questionHistories: [QuestionHistory],
        since: Date = .distantPast
    ) -> Int {
        questionHistories.filter {
            $0.topicID == topic.id &&
            $0.incorrectAttempts > 0 &&
            ($0.lastIncorrectAt ?? .distantPast) >= since
        }.count
    }

    func recentMistakeQuestions(
        for topic: QuizTopic,
        in catalog: CatalogSnapshot,
        questionHistories: [QuestionHistory],
        limit: Int? = nil
    ) -> [Question] {
        let failedIDs = questionHistories
            .filter { $0.topicID == topic.id && $0.incorrectAttempts > 0 }
            .sorted { ($0.lastIncorrectAt ?? .distantPast) > ($1.lastIncorrectAt ?? .distantPast) }
            .compactMap { UUID(uuidString: $0.questionID) }

        let questions = failedIDs.compactMap(catalog.question(for:))
        return limit.map { Array(questions.prefix($0)) } ?? questions
    }

    func learningSummary(from progressEntries: [UserProgress]) -> LearningSummary {
        LearningSummary(
            totalSessions: progressEntries.reduce(0) { $0 + $1.completedSessions },
            totalCorrectAnswers: progressEntries.reduce(0) { $0 + $1.correctAnswers },
            totalIncorrectAnswers: progressEntries.reduce(0) { $0 + $1.incorrectAnswers },
            masteredTopics: progressEntries.filter { $0.highestDifficulty == .hard || $0.accuracyRate >= 0.8 }.count
        )
    }

    func topicSnapshots(in catalog: CatalogSnapshot, progressEntries: [UserProgress]) -> [TopicProgressSnapshot] {
        availableTopics(in: catalog).compactMap { topicProgressSnapshot(for: $0, from: progressEntries) }
    }

    func weakestTopics(
        in catalog: CatalogSnapshot,
        progressEntries: [UserProgress],
        limit: Int = 3
    ) -> [TopicProgressSnapshot] {
        topicSnapshots(in: catalog, progressEntries: progressEntries)
            .sorted { lhs, rhs in
                if lhs.accuracyRate != rhs.accuracyRate {
                    return lhs.accuracyRate < rhs.accuracyRate
                }
                return lhs.completedSessions < rhs.completedSessions
            }
            .prefix(limit)
            .map { $0 }
    }

    func strongestTopics(
        in catalog: CatalogSnapshot,
        progressEntries: [UserProgress],
        limit: Int = 3
    ) -> [TopicProgressSnapshot] {
        topicSnapshots(in: catalog, progressEntries: progressEntries)
            .sorted { lhs, rhs in
                if lhs.accuracyRate != rhs.accuracyRate {
                    return lhs.accuracyRate > rhs.accuracyRate
                }
                return lhs.completedSessions > rhs.completedSessions
            }
            .prefix(limit)
            .map { $0 }
    }

    func dailyReviewPlan(
        in catalog: CatalogSnapshot,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory],
        now: Date = .now
    ) -> DailyReviewPlan {
        let snapshotsByTopic = Dictionary(
            uniqueKeysWithValues: topicSnapshots(in: catalog, progressEntries: progressEntries).map { ($0.topic.id, $0) }
        )

        let scoredTopics = availableTopics(in: catalog).compactMap { topic -> (QuizTopic, Int, Date)? in
            let mistakeCount = recentMistakeCount(for: topic, questionHistories: questionHistories)
            let snapshot = snapshotsByTopic[topic.id]
            let lastUpdate = progressEntries.first(where: { $0.topicID == topic.id })?.lastUpdatedAt ?? .distantPast
            let isStale = snapshot != nil && now.timeIntervalSince(lastUpdate) >= staleTopicThreshold
            let needsReview = snapshot?.accuracyRate ?? 1 < 0.75

            guard mistakeCount > 0 || isStale || needsReview else {
                return nil
            }

            let priority: Int
            if mistakeCount > 0 {
                priority = 3
            } else if needsReview {
                priority = 2
            } else {
                priority = 1
            }

            return (topic, priority, lastUpdate)
        }

        let sortedTopics = scoredTopics
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 > rhs.1
                }
                return lhs.2 < rhs.2
            }
            .map(\.0)

        let recommendations = sortedTopics.map { topic in
            let mistakeCount = recentMistakeCount(for: topic, questionHistories: questionHistories)
            let request = QuizSessionRequest(
                topic: topic,
                strategy: mistakeCount > 0 ? .recentMistakes : .standard,
                questionLimit: mistakeCount > 0 ? 5 : 10,
                presentationMode: .practice,
                launchBehavior: .autoStart
            )

            let subtitle: String
            if mistakeCount > 0 {
                subtitle = "Repaso de errores recientes con \(mistakeCount) preguntas falladas."
            } else {
                subtitle = "Sesion breve para reforzar un tema que lleva tiempo sin repasarse o sigue fragil."
            }

            return ReviewRecommendation(
                request: request,
                title: topic.title,
                subtitle: subtitle
            )
        }

        let staleTopicsCount = scoredTopics.filter { $0.1 == 1 }.count
        let totalMistakeQuestions = sortedTopics.reduce(0) { total, topic in
            total + recentMistakeCount(for: topic, questionHistories: questionHistories)
        }

        return DailyReviewPlan(
            recommendations: recommendations,
            totalMistakeQuestions: totalMistakeQuestions,
            staleTopicsCount: staleTopicsCount
        )
    }

    func topicProgressSnapshot(for topic: QuizTopic, from progressEntries: [UserProgress]) -> TopicProgressSnapshot? {
        guard let progress = progressEntries.first(where: { $0.topicID == topic.id }) else {
            return nil
        }

        return TopicProgressSnapshot(
            topic: topic,
            completedSessions: progress.completedSessions,
            correctAnswers: progress.correctAnswers,
            incorrectAnswers: progress.incorrectAnswers,
            highestDifficulty: progress.highestDifficulty
        )
    }

    func recommendedTopic(from progressEntries: [UserProgress], in catalog: CatalogSnapshot) -> QuizTopic? {
        let topics = availableTopics(in: catalog)

        if let freshTopic = topics.first(where: { topicProgressSnapshot(for: $0, from: progressEntries) == nil }) {
            return freshTopic
        }

        return topics.min { lhs, rhs in
            let left = topicProgressSnapshot(for: lhs, from: progressEntries)
            let right = topicProgressSnapshot(for: rhs, from: progressEntries)
            return recommendationScore(for: left) < recommendationScore(for: right)
        }
    }

    func badges(from progressEntries: [UserProgress]) -> [LearningBadge] {
        let summary = learningSummary(from: progressEntries)
        var badges: [LearningBadge] = []

        if summary.totalSessions >= 1 {
            badges.append(
                LearningBadge(
                    id: "first-session",
                    title: "Primer impulso",
                    subtitle: "Ya has convertido estudio en practica real.",
                    symbolName: "bolt.fill"
                )
            )
        }

        if summary.accuracyRate >= 0.8 && summary.totalAnswers >= 5 {
            badges.append(
                LearningBadge(
                    id: "accuracy",
                    title: "Precision clinica",
                    subtitle: "Mantienes una tasa de acierto alta en tus repasos.",
                    symbolName: "scope"
                )
            )
        }

        if summary.masteredTopics >= 2 {
            badges.append(
                LearningBadge(
                    id: "mastery",
                    title: "Ruta consolidada",
                    subtitle: "Ya hay varios temas con signos claros de dominio.",
                    symbolName: "rosette"
                )
            )
        }

        return badges
    }

    func focusTopic(
        in catalog: CatalogSnapshot,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) -> QuizTopic? {
        if let failedTopic = topics(
            matching: .failedRecently,
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        ).first {
            return failedTopic
        }

        if let reviewTopic = topics(
            matching: .needsReview,
            in: catalog,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        ).first {
            return reviewTopic
        }

        return recommendedTopic(from: progressEntries, in: catalog)
    }

    private func recommendationScore(for snapshot: TopicProgressSnapshot?) -> Double {
        guard let snapshot else { return -1 }
        return Double(snapshot.completedSessions) + snapshot.accuracyRate + Double(snapshot.highestDifficulty.sortOrderValue)
    }

    private func topicSort(_ lhs: QuizTopic, _ rhs: QuizTopic) -> Bool {
        if lhs.system != rhs.system {
            return lhs.system.rawValue < rhs.system.rawValue
        }

        if lhs.mode != rhs.mode {
            return lhs.mode.rawValue < rhs.mode.rawValue
        }

        return lhs.difficulty < rhs.difficulty
    }
}
