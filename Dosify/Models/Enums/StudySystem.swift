import Foundation
import SwiftUI

enum StudySystem: String, CaseIterable, Codable, Identifiable {
    case respiratory
    case cardiovascular
    case nervous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .respiratory:
            return "Respiratorio"
        case .cardiovascular:
            return "Cardiovascular"
        case .nervous:
            return "Nervioso"
        }
    }

    var shortDescription: String {
        switch self {
        case .respiratory:
            return "Farmacos para el manejo de via aerea, bronquios y ventilacion."
        case .cardiovascular:
            return "Tratamientos relacionados con tension arterial, ritmo y perfusion."
        case .nervous:
            return "Principios activos que actuan sobre dolor, sedacion y SNC."
        }
    }

    var symbolName: String {
        switch self {
        case .respiratory:
            return "wind"
        case .cardiovascular:
            return "heart.text.square"
        case .nervous:
            return "brain.head.profile"
        }
    }

    var tintColor: Color {
        switch self {
        case .respiratory:
            return Color(red: 0.14, green: 0.55, blue: 0.50)
        case .cardiovascular:
            return Color(red: 0.80, green: 0.29, blue: 0.28)
        case .nervous:
            return Color(red: 0.39, green: 0.30, blue: 0.71)
        }
    }
}
