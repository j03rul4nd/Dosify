import Foundation
import Testing
@testable import Dosify

struct DrugLibraryViewModelTests {
    @Test
    func filteredDrugsRespectsFavoritesFilter() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        var viewModel = DrugLibraryViewModel()
        viewModel.selectedSystem = .respiratory
        viewModel.selectedCollectionFilter = .favorites

        let respiratoryDrug = try #require(store.drugs(for: .respiratory).first)
        let favorites = [FavoriteDrug(drugID: respiratoryDrug.id.uuidString)]

        let filtered = viewModel.filteredDrugs(store: store, favoriteDrugs: favorites)

        #expect(filtered.count == 1)
        #expect(filtered.first?.id == respiratoryDrug.id)
    }

    @Test
    func filteredDrugsMatchesSearchAcrossNameSummaryAndMechanism() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        var viewModel = DrugLibraryViewModel()
        viewModel.selectedSystem = .respiratory
        viewModel.searchText = "beta"

        let filtered = viewModel.filteredDrugs(store: store, favoriteDrugs: [])

        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy {
            $0.name.localizedCaseInsensitiveContains("beta") ||
            $0.summary.localizedCaseInsensitiveContains("beta") ||
            $0.mechanism.localizedCaseInsensitiveContains("beta")
        })
    }

    @Test
    func groupedDrugsOnlyReturnsCategoriesWithContent() {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        var viewModel = DrugLibraryViewModel()
        viewModel.selectedSystem = .respiratory

        let grouped = viewModel.groupedDrugs(store: store, favoriteDrugs: [])

        #expect(!grouped.isEmpty)
        #expect(grouped.allSatisfy { !$0.1.isEmpty })
    }

    @Test
    func practiceTopicUsesStoreRecommendationForDrug() throws {
        let store = DosifyStore(loader: SeedDataLoader { _, _ in nil })
        let drug = try #require(store.drugs(for: .respiratory).first)
        let viewModel = DrugLibraryViewModel()

        let topic = viewModel.practiceTopic(for: drug, store: store)

        #expect(topic?.system == drug.system)
    }
}
