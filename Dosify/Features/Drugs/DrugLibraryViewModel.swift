import Foundation

struct DrugLibraryViewModel {
    var selectedSystem: StudySystem = .respiratory
    var selectedCollectionFilter: LibraryCollectionFilter = .all
    var searchText: String = ""

    func filteredDrugs(store: DosifyStore, favoriteDrugs: [FavoriteDrug]) -> [Drug] {
        let baseDrugs = store.drugs(for: selectedSystem)
        let favoriteIDs = store.favoriteDrugIDs(from: favoriteDrugs)
        let drugs: [Drug]

        switch selectedCollectionFilter {
        case .all:
            drugs = baseDrugs
        case .favorites:
            drugs = baseDrugs.filter { favoriteIDs.contains($0.id.uuidString) }
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return drugs }

        return drugs.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.summary.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.mechanism.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    func groupedDrugs(store: DosifyStore, favoriteDrugs: [FavoriteDrug]) -> [(DrugCategory, [Drug])] {
        let drugs = filteredDrugs(store: store, favoriteDrugs: favoriteDrugs)

        return DrugCategory.allCases.compactMap { category in
            let categoryDrugs = drugs.filter { $0.category == category }
            guard !categoryDrugs.isEmpty else { return nil }
            return (category, categoryDrugs)
        }
    }

    func isFavorite(_ drug: Drug, store: DosifyStore, favoriteDrugs: [FavoriteDrug]) -> Bool {
        store.isFavorite(drug: drug, favorites: favoriteDrugs)
    }

    func practiceTopic(for drug: Drug, store: DosifyStore) -> QuizTopic? {
        store.practiceTopic(for: drug)
    }
}
