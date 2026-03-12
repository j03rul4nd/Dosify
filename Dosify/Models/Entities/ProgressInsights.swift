import Foundation

struct DailyReviewPlan {
    let recommendations: [ReviewRecommendation]
    let totalMistakeQuestions: Int
    let staleTopicsCount: Int

    var dueTopics: [QuizTopic] {
        recommendations.map(\.request.topic)
    }

    var dueTopicsCount: Int {
        recommendations.count
    }
}

struct ReviewRecommendation: Identifiable, Equatable {
    let request: QuizSessionRequest
    let title: String
    let subtitle: String

    var id: String {
        request.id
    }
}
