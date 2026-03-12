import Foundation

struct Drug: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let system: StudySystem
    let category: DrugCategory
    let summary: String
    let mechanism: String
    let uses: [String]
    let notes: [String]

    var isValidForCatalog: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
