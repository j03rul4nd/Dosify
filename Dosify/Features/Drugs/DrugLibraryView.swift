import OSLog
import SwiftData
import SwiftUI

struct DrugLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteDrug.createdAt, order: .reverse) private var favoriteDrugs: [FavoriteDrug]

    @ObservedObject var store: DosifyStore
    @Binding var selectedTab: RootTab
    @Binding var pendingQuizRequest: QuizSessionRequest?
    @State private var viewModel = DrugLibraryViewModel()
    @State private var selectedDrug: Drug?
    @State private var alertState: DrugLibraryAlertState?

    init(
        store: DosifyStore,
        selectedTab: Binding<RootTab> = .constant(.library),
        pendingQuizRequest: Binding<QuizSessionRequest?> = .constant(nil)
    ) {
        self.store = store
        _selectedTab = selectedTab
        _pendingQuizRequest = pendingQuizRequest
    }

    private var filteredDrugs: [Drug] {
        viewModel.filteredDrugs(store: store, favoriteDrugs: favoriteDrugs)
    }

    private var groupedDrugs: [(DrugCategory, [Drug])] {
        viewModel.groupedDrugs(store: store, favoriteDrugs: favoriteDrugs)
    }

    private var summarySubtitle: String {
        viewModel.selectedSystem.shortDescription
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DashboardHeaderCard(
                        eyebrow: "Biblioteca",
                        title: viewModel.selectedSystem.title,
                        subtitle: summarySubtitle
                    ) {
                        HStack(spacing: 12) {
                            CapsuleTag(title: "\(filteredDrugs.count) farmacos", tint: .white)
                            CapsuleTag(title: "\(groupedDrugs.count) categorias", tint: .white)
                            if viewModel.selectedCollectionFilter == .favorites {
                                CapsuleTag(title: "Favoritos", tint: .white)
                            }
                        }
                    }

                    systemSelectorSection
                    libraryFilterSection
                    catalogSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color(red: 0.95, green: 0.97, blue: 0.96))
            .navigationTitle("Farmacos")
            .searchable(text: $viewModel.searchText, prompt: "Buscar por nombre, resumen o mecanismo")
            .navigationDestination(item: $selectedDrug) { drug in
                DrugDetailView(
                    store: store,
                    selectedTab: $selectedTab,
                    pendingQuizRequest: $pendingQuizRequest,
                    drug: drug
                )
            }
            .alert(item: $alertState) { state in
                Alert(
                    title: Text(state.title),
                    message: Text(state.message),
                    dismissButton: .default(Text("Cerrar"))
                )
            }
        }
    }

    private var systemSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(
                title: "Sistemas",
                subtitle: "Cambia rapido de contexto clinico y filtra el contenido relevante."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.systems) { system in
                        systemCard(for: system)
                    }
                }
            }
        }
    }

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitleView(
                title: "Catalogo filtrado",
                subtitle: "Busca un farmaco concreto o repasa por categoria farmacologica."
            )

            if groupedDrugs.isEmpty {
                SurfaceCard {
                    Text("No hay resultados para tu busqueda actual.")
                        .font(.headline)
                    Text("Prueba otro termino o cambia de sistema.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedDrugs, id: \.0) { category, drugs in
                    categorySection(category: category, drugs: drugs)
                }
            }
        }
    }

    private var libraryFilterSection: some View {
        SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
            SectionTitleView(
                title: "Coleccion",
                subtitle: "Alterna entre todo el catalogo del sistema y tus farmacos guardados."
            )

            HStack(spacing: 10) {
                ForEach(LibraryCollectionFilter.allCases) { filter in
                    FilterPill(
                        title: filter.title,
                        isSelected: viewModel.selectedCollectionFilter == filter,
                        tint: viewModel.selectedSystem.tintColor
                    ) {
                        viewModel.selectedCollectionFilter = filter
                    }
                }
            }
        }
    }

    private func systemCard(for system: StudySystem) -> some View {
        let isSelected = viewModel.selectedSystem == system

        return Button {
            viewModel.selectedSystem = system
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: system.symbolName)
                    .font(.title3.weight(.semibold))
                Text(system.title)
                    .font(.headline)
                Text(system.shortDescription)
                    .font(.caption)
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(16)
            .frame(width: 210, alignment: .leading)
            .background(
                isSelected ? system.tintColor : Color.white,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func categorySection(category: DrugCategory, drugs: [Drug]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.title)
                    .font(.headline)
                Spacer()
                CapsuleTag(title: "\(drugs.count)", tint: viewModel.selectedSystem.tintColor)
            }

            ForEach(drugs) { drug in
                drugCard(for: drug)
            }
        }
    }

    private func drugCard(for drug: Drug) -> some View {
        let isFavorite = viewModel.isFavorite(drug, store: store, favoriteDrugs: favoriteDrugs)

        return SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(drug.name)
                        .font(.headline)
                    Text(drug.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                CapsuleTag(title: drug.category.title, tint: viewModel.selectedSystem.tintColor)
            }

            Button {
                selectedDrug = drug
            } label: {
                Label("Ver detalle completo", systemImage: "arrow.right.circle")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.selectedSystem.tintColor)

            LabeledContent("Mecanismo", value: drug.mechanism)

            if !drug.uses.isEmpty {
                LabeledContent("Usos", value: drug.uses.joined(separator: ", "))
            }

            if !drug.notes.isEmpty {
                LabeledContent("Notas", value: drug.notes.joined(separator: " · "))
            }

            HStack(spacing: 12) {
                Button {
                    toggleFavorite(for: drug)
                } label: {
                    Label(
                        isFavorite ? "Guardado" : "Guardar",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                }
                .buttonStyle(.bordered)
                .tint(isFavorite ? .pink : viewModel.selectedSystem.tintColor)

                Button {
                    startPractice(for: drug)
                } label: {
                    Label("Practicar este sistema", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.selectedSystem.tintColor)
            }
        }
    }

    private func toggleFavorite(for drug: Drug) {
        let drugID = drug.id.uuidString

        if let existingFavorite = favoriteDrugs.first(where: { $0.drugID == drugID }) {
            modelContext.delete(existingFavorite)
        } else {
            modelContext.insert(FavoriteDrug(drugID: drugID))
        }

        do {
            try modelContext.save()
        } catch {
            AppLogger.persistence.error("Failed to persist favorite for drug \(drugID, privacy: .public): \(error.localizedDescription, privacy: .public)")
            alertState = DrugLibraryAlertState(
                title: "No se pudo actualizar el favorito",
                message: QuizSessionError.favoriteSaveFailed(drugID: drugID).localizedDescription
            )
        }
    }

    private func startPractice(for drug: Drug) {
        guard let topic = viewModel.practiceTopic(for: drug, store: store) else {
            alertState = DrugLibraryAlertState(
                title: "Sin quiz disponible",
                message: "Todavia no hay preguntas configuradas para este sistema."
            )
            return
        }

        pendingQuizRequest = QuizSessionRequest(topic: topic)
        selectedTab = .quiz
    }
}

#Preview {
    DrugLibraryView(store: DosifyStore())
        .modelContainer(for: [UserProgress.self, FavoriteDrug.self, QuestionHistory.self], inMemory: true)
}

private struct DrugLibraryAlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
