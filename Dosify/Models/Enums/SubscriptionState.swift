import Foundation

enum SubscriptionState: String, Codable {
    case freeWithAds
    case premium

    var title: String {
        switch self {
        case .freeWithAds:
            return "Gratis con anuncios"
        case .premium:
            return "Premium sin anuncios"
        }
    }
}
