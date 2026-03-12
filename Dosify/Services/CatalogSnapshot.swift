import Foundation

struct CatalogIssue: Identifiable, Hashable {
    enum Severity: String {
        case warning
        case error
    }

    let id = UUID()
    let severity: Severity
    let source: String
    let message: String
}

struct CatalogLoadResult {
    let drugs: [Drug]
    let questions: [Question]
    let issues: [CatalogIssue]
}

struct CatalogSnapshot {
    static let empty = CatalogSnapshot(drugs: [], questions: [])

    let drugs: [Drug]
    let questions: [Question]

    private let drugsBySystem: [StudySystem: [Drug]]
    private let questionsByTopic: [QuizTopic: [Question]]
    private let questionsByID: [UUID: Question]

    init(drugs: [Drug], questions: [Question]) {
        self.drugs = drugs
        self.questions = questions
        self.drugsBySystem = Dictionary(grouping: drugs, by: \.system)
        self.questionsByTopic = Dictionary(grouping: questions, by: \.topic)
        self.questionsByID = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
    }

    var availableSystems: [StudySystem] {
        StudySystem.allCases.filter { system in
            !(drugsBySystem[system] ?? []).isEmpty || questions.contains { $0.system == system }
        }
    }

    func drugs(for system: StudySystem) -> [Drug] {
        drugsBySystem[system, default: []]
    }

    func questions(for topic: QuizTopic) -> [Question] {
        questionsByTopic[topic, default: []]
    }

    func question(for id: UUID) -> Question? {
        questionsByID[id]
    }
}
