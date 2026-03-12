import Foundation
import Testing
@testable import Dosify

struct SeedDataLoaderTests {
    @Test
    func loadCatalogUsesInjectedJSONResources() throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let drugs = """
        [
          {
            "id": "77777777-7777-7777-7777-777777777777",
            "name": "Metoprolol",
            "system": "cardiovascular",
            "category": "diseaseControl",
            "summary": "Betabloqueante cardioselectivo.",
            "mechanism": "Disminuye frecuencia cardiaca y contractilidad.",
            "uses": ["HTA", "Angina"],
            "notes": ["Vigilar FC"]
          }
        ]
        """

        let questions = """
        [
          {
            "id": "BBBBBBB1-BBBB-BBBB-BBBB-BBBBBBBBBBB1",
            "prompt": "Que farmaco disminuye la frecuencia cardiaca?",
            "mode": "multipleChoice",
            "difficulty": "easy",
            "system": "cardiovascular",
            "category": "diseaseControl",
            "correctAnswer": "Metoprolol",
            "options": ["Metoprolol", "Salbutamol", "Diazepam"],
            "explanation": "Metoprolol es un betabloqueante cardioselectivo."
          }
        ]
        """

        try drugs.write(to: directoryURL.appending(path: "drugs.json"), atomically: true, encoding: .utf8)
        try questions.write(to: directoryURL.appending(path: "questions.json"), atomically: true, encoding: .utf8)

        let loader = SeedDataLoader { filename, fileExtension in
            directoryURL.appending(path: "\(filename).\(fileExtension)")
        }

        let result = loader.loadCatalog()

        #expect(result.issues.isEmpty)
        #expect(result.drugs.count == 1)
        #expect(result.questions.count == 1)
        #expect(result.drugs.first?.name == "Metoprolol")
        #expect(result.questions.first?.correctAnswer == "Metoprolol")
    }

    @Test
    func loadCatalogFallsBackWhenResourcesAreMissing() {
        let loader = SeedDataLoader { _, _ in nil }

        let result = loader.loadCatalog()

        #expect(result.drugs.count == SampleCatalog.drugs.count)
        #expect(result.questions.count == SampleCatalog.questions.count)
        #expect(result.issues.count == 2)
        #expect(result.issues.allSatisfy { $0.source == "drugs" || $0.source == "questions" })
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
