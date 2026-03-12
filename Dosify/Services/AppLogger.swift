import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Dosify"

    static let catalog = Logger(subsystem: subsystem, category: "Catalog")
    static let quiz = Logger(subsystem: subsystem, category: "Quiz")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
}
