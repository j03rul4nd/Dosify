import Foundation
import SwiftUI

struct HomeDashboardViewModel {
    let summary: LearningSummary
    let recommendedTopic: QuizTopic?
    let focusTopic: QuizTopic?
    let badges: [LearningBadge]
    let dailyReviewPlan: DailyReviewPlan
    let systemsCount: Int
    let recentMistakesCount: Int
    let favoriteDrugsCount: Int

    init(
        store: DosifyStore,
        progressEntries: [UserProgress],
        questionHistories: [QuestionHistory],
        favoriteDrugs: [FavoriteDrug]
    ) {
        self.summary = store.learningSummary(from: progressEntries)
        self.recommendedTopic = store.recommendedTopic(from: progressEntries)
        self.focusTopic = store.focusTopic(progressEntries: progressEntries, questionHistories: questionHistories)
        self.badges = store.badges(from: progressEntries)
        self.dailyReviewPlan = store.dailyReviewPlan(
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
        self.systemsCount = store.systems.count
        self.recentMistakesCount = questionHistories.reduce(0) { $0 + $1.incorrectAttempts }
        self.favoriteDrugsCount = favoriteDrugs.count
    }

    var primaryActionTopic: QuizTopic? {
        focusTopic ?? recommendedTopic
    }

    var isFirstLaunchExperience: Bool {
        summary.totalSessions == 0
    }

    var heroEyebrow: String {
        isFirstLaunchExperience ? "Bienvenido a Dosify" : "Tu centro de estudio"
    }

    var heroTitle: String {
        isFirstLaunchExperience ? "Empieza con claridad, no con caos." : "Vuelve a tu siguiente mejor paso."
    }

    var heroSubtitle: String {
        if isFirstLaunchExperience {
            return "Dosify une teoria y practica para que no estudies farmacos como listas sueltas, sino como rutas de memoria accionables."
        }

        if dailyReviewPlan.dueTopicsCount > 0 {
            return "Tienes \(dailyReviewPlan.dueTopicsCount) temas listos para repasar hoy. Retomar ahora es la forma mas rapida de consolidar memoria."
        }

        if recentMistakesCount > 0 {
            return "Hoy tienes material real para reforzar: errores recientes, progreso visible y un siguiente paso listo para continuar."
        }

        return "Retoma tu ritmo con foco, progreso visible y sesiones pensadas para reforzar justo lo que mas lo necesita."
    }

    var primaryActionTitle: String {
        isFirstLaunchExperience ? "Empezar a estudiar" : "Continuar ahora"
    }

    var focusSupportingText: String {
        "\(recentMistakesCount) errores acumulados, \(favoriteDrugsCount) favoritos guardados."
    }

    var reviewTopicForToday: QuizTopic? {
        dailyReviewPlan.recommendations.first?.request.topic
    }

    var reviewRecommendationForToday: ReviewRecommendation? {
        dailyReviewPlan.recommendations.first
    }

    var metricItems: [HomeMetricItem] {
        [
            HomeMetricItem(
                title: "Sesiones completadas",
                value: "\(summary.totalSessions)",
                symbolName: "bolt.heart",
                tint: Color(red: 0.15, green: 0.53, blue: 0.47)
            ),
            HomeMetricItem(
                title: "Precision global",
                value: summary.accuracyPercentageText,
                symbolName: "target",
                tint: Color(red: 0.86, green: 0.43, blue: 0.20)
            ),
            HomeMetricItem(
                title: "Temas dominados",
                value: "\(summary.masteredTopics)",
                symbolName: "rosette",
                tint: Color(red: 0.25, green: 0.39, blue: 0.80)
            ),
            HomeMetricItem(
                title: "Sistemas activos",
                value: "\(systemsCount)",
                symbolName: "cross.case.circle",
                tint: Color(red: 0.45, green: 0.26, blue: 0.67)
            )
        ]
    }
}

struct HomeMetricItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let symbolName: String
    let tint: Color
}
