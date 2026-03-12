import Foundation

enum DrugCategory: String, CaseIterable, Codable, Identifiable {
    case symptomRelief
    case diseaseControl
    case emergencySupport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .symptomRelief:
            return "Alivio sintomatico"
        case .diseaseControl:
            return "Control de enfermedad"
        case .emergencySupport:
            return "Soporte critico"
        }
    }
}
