import Foundation
import OSLog

struct SeedDataLoader {
    typealias ResourceProvider = (_ filename: String, _ fileExtension: String) -> URL?

    private let resourceProvider: ResourceProvider

    init(resourceProvider: @escaping ResourceProvider = { filename, fileExtension in
        Bundle.main.url(forResource: filename, withExtension: fileExtension)
    }) {
        self.resourceProvider = resourceProvider
    }

    func loadCatalog() -> CatalogLoadResult {
        let drugResult: ResourceLoadResult<Drug> = loadJSON(
            filename: "drugs",
            fallback: SampleCatalog.drugs
        )
        let questionResult: ResourceLoadResult<Question> = loadJSON(
            filename: "questions",
            fallback: SampleCatalog.questions
        )

        let validDrugs = drugResult.values.filter(\.isValidForCatalog)
        let invalidDrugCount = drugResult.values.count - validDrugs.count

        let sanitizedQuestions = questionResult.values.compactMap { question -> Question? in
            do {
                try question.validateConfiguration()
                return question
            } catch {
                AppLogger.catalog.error("\(error.localizedDescription, privacy: .public)")
                return question.sanitizedForCatalog()
            }
        }
        let invalidQuestionCount = questionResult.values.count - sanitizedQuestions.count

        var issues = drugResult.issues + questionResult.issues

        if invalidDrugCount > 0 {
            issues.append(
                CatalogIssue(
                    severity: .warning,
                    source: "drugs",
                    message: "Se descartaron \(invalidDrugCount) farmacos invalidos del catalogo."
                )
            )
        }

        if invalidQuestionCount > 0 {
            issues.append(
                CatalogIssue(
                    severity: .warning,
                    source: "questions",
                    message: "Se descartaron \(invalidQuestionCount) preguntas invalidas del catalogo."
                )
            )
        }

        return CatalogLoadResult(
            drugs: validDrugs,
            questions: sanitizedQuestions,
            issues: issues
        )
    }

    private func loadJSON<T: Decodable>(filename: String, fallback: [T]) -> ResourceLoadResult<T> {
        guard let url = resourceProvider(filename, "json") else {
            let issue = CatalogIssue(
                severity: .warning,
                source: filename,
                message: "No se encontro \(filename).json en el bundle. Se usan datos fallback."
            )
            AppLogger.catalog.error("\(issue.message, privacy: .public)")
            return ResourceLoadResult(values: fallback, issues: [issue])
        }

        do {
            let data = try Data(contentsOf: url)
            let values = try JSONDecoder().decode([T].self, from: data)
            return ResourceLoadResult(values: values, issues: [])
        } catch {
            let issue = CatalogIssue(
                severity: .error,
                source: filename,
                message: "No se pudo decodificar \(filename).json. Se usan datos fallback."
            )
            AppLogger.catalog.error("\(issue.message, privacy: .public)")
            return ResourceLoadResult(values: fallback, issues: [issue])
        }
    }
}

private struct ResourceLoadResult<T> {
    let values: [T]
    let issues: [CatalogIssue]
}

enum SampleCatalog {
    static let drugs: [Drug] = [
        Drug(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Salbutamol",
            system: .respiratory,
            category: .emergencySupport,
            summary: "Broncodilatador de accion rapida usado en broncoespasmo.",
            mechanism: "Agonista beta-2 que relaja musculo liso bronquial.",
            uses: ["Crisis asmatica", "Broncoespasmo inducido por esfuerzo"],
            notes: ["Vigilar temblor y taquicardia", "Uso frecuente indica mal control"]
        ),
        Drug(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Budesonida",
            system: .respiratory,
            category: .diseaseControl,
            summary: "Corticoide inhalado para control mantenido del asma.",
            mechanism: "Reduce inflamacion de la via aerea y la hiperreactividad bronquial.",
            uses: ["Asma persistente", "Prevencion de exacerbaciones"],
            notes: ["No alivia crisis agudas", "Enjuague bucal tras inhalacion"]
        ),
        Drug(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Enalapril",
            system: .cardiovascular,
            category: .diseaseControl,
            summary: "IECA empleado en hipertension e insuficiencia cardiaca.",
            mechanism: "Disminuye la conversion de angiotensina I en II.",
            uses: ["Hipertension arterial", "Insuficiencia cardiaca"],
            notes: ["Controlar tension y funcion renal", "Puede provocar tos seca"]
        ),
        Drug(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "Nitroglicerina",
            system: .cardiovascular,
            category: .symptomRelief,
            summary: "Vasodilatador utilizado para aliviar angina.",
            mechanism: "Libera oxido nitrico y disminuye precarga cardiaca.",
            uses: ["Angina estable", "Dolor toracico isquemico"],
            notes: ["Vigilar hipotension", "Contraindicada con inhibidores PDE-5"]
        ),
        Drug(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            name: "Paracetamol",
            system: .nervous,
            category: .symptomRelief,
            summary: "Analgesico y antipiretico de uso comun.",
            mechanism: "Modula vias centrales del dolor y la temperatura.",
            uses: ["Fiebre", "Dolor leve o moderado"],
            notes: ["Atencion a dosis maxima diaria", "Precaucion en hepatopatia"]
        ),
        Drug(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            name: "Diazepam",
            system: .nervous,
            category: .emergencySupport,
            summary: "Benzodiacepina para ansiedad aguda, convulsiones y sedacion.",
            mechanism: "Potencia la accion inhibitoria del GABA.",
            uses: ["Crisis convulsiva", "Ansiedad aguda", "Sedacion"],
            notes: ["Riesgo de depresion respiratoria", "Valorar somnolencia y dependencia"]
        )
    ]

    static let questions: [Question] = [
        Question(
            id: UUID(uuidString: "AAAAAAA1-AAAA-AAAA-AAAA-AAAAAAAAAAA1")!,
            prompt: "Que farmaco se usa como broncodilatador de accion rapida?",
            mode: .multipleChoice,
            difficulty: .easy,
            system: .respiratory,
            category: .emergencySupport,
            correctAnswer: "Salbutamol",
            options: ["Budesonida", "Salbutamol", "Enalapril", "Diazepam"],
            explanation: "Salbutamol actua rapidamente sobre receptores beta-2 y es util en broncoespasmo."
        ),
        Question(
            id: UUID(uuidString: "AAAAAAA2-AAAA-AAAA-AAAA-AAAAAAAAAAA2")!,
            prompt: "Empareja el corticoide inhalado con control mantenido del asma.",
            mode: .matching,
            difficulty: .easy,
            system: .respiratory,
            category: .diseaseControl,
            correctAnswer: "Budesonida",
            options: ["Nitroglicerina", "Budesonida", "Paracetamol", "Diazepam"],
            explanation: "Budesonida no resuelve la crisis aguda, pero reduce inflamacion cronica."
        ),
        Question(
            id: UUID(uuidString: "AAAAAAA3-AAAA-AAAA-AAAA-AAAAAAAAAAA3")!,
            prompt: "Cual de estos farmacos pertenece al grupo de los IECAs?",
            mode: .multipleChoice,
            difficulty: .medium,
            system: .cardiovascular,
            category: .diseaseControl,
            correctAnswer: "Enalapril",
            options: ["Enalapril", "Salbutamol", "Paracetamol", "Diazepam"],
            explanation: "Enalapril inhibe la enzima convertidora de angiotensina."
        ),
        Question(
            id: UUID(uuidString: "AAAAAAA4-AAAA-AAAA-AAAA-AAAAAAAAAAA4")!,
            prompt: "Que farmaco se emplea para aliviar la angina por vasodilatacion?",
            mode: .matching,
            difficulty: .medium,
            system: .cardiovascular,
            category: .symptomRelief,
            correctAnswer: "Nitroglicerina",
            options: ["Budesonida", "Nitroglicerina", "Enalapril", "Diazepam"],
            explanation: "Nitroglicerina reduce demanda miocardica de oxigeno y alivia dolor anginoso."
        ),
        Question(
            id: UUID(uuidString: "AAAAAAA5-AAAA-AAAA-AAAA-AAAAAAAAAAA5")!,
            prompt: "Que precaucion principal exige el paracetamol?",
            mode: .multipleChoice,
            difficulty: .easy,
            system: .nervous,
            category: .symptomRelief,
            correctAnswer: "No superar la dosis maxima diaria",
            options: ["No superar la dosis maxima diaria", "Usarlo solo por via inhalada", "Mezclarlo con nitratos", "Evitarlo por su tos seca"],
            explanation: "El riesgo clave es hepatotoxicidad si se supera la dosis recomendada."
        ),
        Question(
            id: UUID(uuidString: "AAAAAAA6-AAAA-AAAA-AAAA-AAAAAAAAAAA6")!,
            prompt: "Que efecto adverso obliga a vigilar diazepam en un contexto agudo?",
            mode: .multipleChoice,
            difficulty: .hard,
            system: .nervous,
            category: .emergencySupport,
            correctAnswer: "Depresion respiratoria",
            options: ["Hiperglucemia", "Depresion respiratoria", "Broncoespasmo", "Tos seca"],
            explanation: "Las benzodiacepinas pueden comprometer respiracion y nivel de consciencia."
        )
    ]
}
