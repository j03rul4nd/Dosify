import Foundation

struct Question: Codable, Identifiable, Hashable {
    let id: UUID
    let prompt: String
    let mode: QuizMode
    let difficulty: DifficultyLevel
    let system: StudySystem
    let category: DrugCategory
    let correctAnswer: String
    let options: [String]
    let explanation: String

    var topic: QuizTopic {
        QuizTopic(system: system, mode: mode, difficulty: difficulty)
    }

    func validateConfiguration(expectedMode: QuizMode? = nil) throws {
        let cleanedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAnswer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedOptions = normalizedOptions

        guard !cleanedPrompt.isEmpty else {
            throw QuizSessionError.invalidQuestion(id, reason: "La pregunta \(id.uuidString) tiene un enunciado vacio.")
        }

        guard !cleanedAnswer.isEmpty else {
            throw QuizSessionError.invalidQuestion(id, reason: "La pregunta \(id.uuidString) no tiene respuesta correcta.")
        }

        guard cleanedOptions.count >= 2 else {
            throw QuizSessionError.invalidQuestion(id, reason: "La pregunta \(id.uuidString) necesita al menos dos opciones validas.")
        }

        guard cleanedOptions.contains(cleanedAnswer) else {
            throw QuizSessionError.invalidQuestion(id, reason: "La pregunta \(id.uuidString) no contiene la respuesta correcta entre sus opciones.")
        }

        if let expectedMode, mode != expectedMode {
            throw QuizSessionError.invalidQuestion(
                id,
                reason: "La pregunta \(id.uuidString) pertenece a \(mode.rawValue) pero la sesion esperaba \(expectedMode.rawValue)."
            )
        }
    }

    func sanitizedForCatalog() -> Question? {
        let cleanedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAnswer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedExplanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedOptions = normalizedOptions

        let sanitized = Question(
            id: id,
            prompt: cleanedPrompt,
            mode: mode,
            difficulty: difficulty,
            system: system,
            category: category,
            correctAnswer: cleanedAnswer,
            options: cleanedOptions,
            explanation: cleanedExplanation
        )

        do {
            try sanitized.validateConfiguration()
            return sanitized
        } catch {
            return nil
        }
    }

    private var normalizedOptions: [String] {
        var seen = Set<String>()

        return options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }
}
