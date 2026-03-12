import Foundation
import SwiftData

@Model
final class FavoriteDrug {
    @Attribute(.unique) var drugID: String
    var createdAt: Date

    init(drugID: String, createdAt: Date = .now) {
        self.drugID = drugID
        self.createdAt = createdAt
    }
}
