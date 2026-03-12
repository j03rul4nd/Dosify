import Foundation
import Testing
@testable import Dosify

struct QuestionValidationTests {
    @Test
    func validateConfigurationRejectsQuestionWithoutCorrectAnswerInOptions() {
        let question = Question(
            id: UUID(),
            prompt: "Selecciona el broncodilatador",
            mode: .multipleChoice,
            difficulty: .easy,
            system: .respiratory,
            category: .emergencySupport,
            correctAnswer: "Salbutamol",
            options: ["Budesonida", "Diazepam"],
            explanation: "Salbutamol se usa en broncoespasmo."
        )

        var didThrow = false

        do {
            try question.validateConfiguration()
        } catch {
            didThrow = true
        }

        #expect(didThrow)
    }

    @Test
    func sanitizedForCatalogTrimsAndDeduplicatesOptions() throws {
        let question = Question(
            id: UUID(),
            prompt: "  Selecciona el farmaco correcto  ",
            mode: .matching,
            difficulty: .medium,
            system: .cardiovascular,
            category: .diseaseControl,
            correctAnswer: " Enalapril ",
            options: [" Enalapril ", "Enalapril", " ", "Salbutamol"],
            explanation: "  Enalapril es un IECA. "
        )

        let sanitized = try #require(question.sanitizedForCatalog())

        #expect(sanitized.prompt == "Selecciona el farmaco correcto")
        #expect(sanitized.correctAnswer == "Enalapril")
        #expect(sanitized.options == ["Enalapril", "Salbutamol"])
        #expect(sanitized.explanation == "Enalapril es un IECA.")
    }
}
