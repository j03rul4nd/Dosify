import Foundation
import SwiftUI

struct ProgressOverviewViewModel {
    let summary: LearningSummary
    let badges: [LearningBadge]
    let strongestTopics: [TopicProgressSnapshot]
    let weakestTopics: [TopicProgressSnapshot]
    let dailyReviewPlan: DailyReviewPlan

    init(
        store: DosifyStore,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory]
    ) {
        self.summary = store.learningSummary(from: progressEntries)
        self.badges = store.badges(from: progressEntries)
        self.strongestTopics = store.strongestTopics(from: progressEntries)
        self.weakestTopics = store.weakestTopics(from: progressEntries)
        self.dailyReviewPlan = store.dailyReviewPlan(
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    var hasProgress: Bool {
        summary.totalSessions > 0
    }

    var dueTodayTitle: String {
        dailyReviewPlan.dueTopics.isEmpty ? "Sin repaso pendiente" : "Repasar hoy"
    }

    var dueTodaySubtitle: String {
        if dailyReviewPlan.dueTopics.isEmpty {
            return "No hay temas urgentes ahora mismo. Buen momento para consolidar o explorar nuevo contenido."
        }

        return "\(dailyReviewPlan.dueTopicsCount) temas pendientes, \(dailyReviewPlan.totalMistakeQuestions) preguntas ligadas a errores y \(dailyReviewPlan.staleTopicsCount) temas que llevan tiempo sin repasarse."
    }

    var primaryReviewTopic: QuizTopic? {
        dailyReviewPlan.recommendations.first?.request.topic
    }

    var primaryRecommendation: ReviewRecommendation? {
        dailyReviewPlan.recommendations.first
    }

    var metricItems: [HomeMetricItem] {
        [
            HomeMetricItem(
                title: "Sesiones",
                value: "\(summary.totalSessions)",
                symbolName: "bolt.heart",
                tint: Color(red: 0.15, green: 0.53, blue: 0.47)
            ),
            HomeMetricItem(
                title: "Precision",
                value: summary.accuracyPercentageText,
                symbolName: "target",
                tint: Color(red: 0.86, green: 0.43, blue: 0.20)
            ),
            HomeMetricItem(
                title: "Dominados",
                value: "\(summary.masteredTopics)",
                symbolName: "rosette",
                tint: Color(red: 0.25, green: 0.39, blue: 0.80)
            ),
            HomeMetricItem(
                title: "Para hoy",
                value: "\(dailyReviewPlan.dueTopicsCount)",
                symbolName: "calendar.badge.clock",
                tint: Color(red: 0.42, green: 0.33, blue: 0.75)
            )
        ]
    }
}
