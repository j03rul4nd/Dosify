import SwiftData
import SwiftUI

struct QuizHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProgress.lastUpdatedAt, order: .reverse) private var progressEntries: [UserProgress]
    @Query(sort: \QuestionHistory.lastAnsweredAt, order: .reverse) private var questionHistories: [QuestionHistory]

    @ObservedObject var store: DosifyStore
    @Binding var pendingRequest: QuizSessionRequest?
    @State private var viewModel = QuizHubViewModel()
    @State private var activeDraft: QuizSessionDraft?
    @State private var resumableDraft: QuizSessionDraft?
    @State private var alertState: QuizHubAlertState?
    @State private var hasRestoredPersistedDraft = false

    private let progressRecorder = ProgressRecorder()
    private let draftStore = QuizDraftStore()

    private var filteredQuestions: [Question] {
        viewModel.filteredQuestions(store: store)
    }

    private var selectedTopic: QuizTopic {
        viewModel.selectedTopic
    }

    private var selectedTopicProgress: UserProgress? {
        viewModel.selectedTopicProgress(from: progressEntries)
    }

    private var selectedTopicAccuracyText: String {
        viewModel.selectedTopicAccuracyText(from: progressEntries)
    }

    private var filteredTopics: [QuizTopic] {
        viewModel.filteredTopics(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    private var relatedTopics: [QuizTopic] {
        viewModel.relatedTopics(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    private var recentMistakesCount: Int {
        viewModel.recentMistakesCount(store: store, questionHistories: questionHistories)
    }

    init(store: DosifyStore, pendingRequest: Binding<QuizSessionRequest?> = .constant(nil)) {
        self.store = store
        _pendingRequest = pendingRequest
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heroSection
                    configurationSection
                    topicCollectionsSection

                    if let resumableDraft {
                        SurfaceCard(tint: resumableDraft.session.topic.system.tintColor) {
                            SectionTitleView(
                                title: "Sesion en pausa",
                                subtitle: "Puedes retomar exactamente donde la dejaste sin perder contexto ni progreso."
                            )

                            Text(resumableDraft.session.topic.title)
                                .font(.headline)
                            Text("Pregunta \(resumableDraft.currentIndex + 1) de \(resumableDraft.session.questions.count)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button("Reanudar sesion") {
                                activeDraft = resumableDraft
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(resumableDraft.session.topic.system.tintColor)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricTile(
                            title: "Preguntas listas",
                            value: "\(filteredQuestions.count)",
                            symbolName: "square.stack.3d.up",
                            tint: viewModel.selectedSystem.tintColor
                        )
                        MetricTile(
                            title: "Aciertos",
                            value: "\(selectedTopicProgress?.correctAnswers ?? 0)",
                            symbolName: "checkmark.seal",
                            tint: Color(red: 0.19, green: 0.61, blue: 0.32)
                        )
                        MetricTile(
                            title: "Sesiones",
                            value: "\(selectedTopicProgress?.completedSessions ?? 0)",
                            symbolName: "flag.2.crossed",
                            tint: Color(red: 0.86, green: 0.43, blue: 0.20)
                        )
                        MetricTile(
                            title: "Precision",
                            value: selectedTopicAccuracyText,
                            symbolName: "scope",
                            tint: Color(red: 0.25, green: 0.39, blue: 0.80)
                        )
                    }

                    SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
                        SectionTitleView(
                            title: "Lanzar sesion",
                            subtitle: viewModel.launchSubtitle(from: progressEntries)
                        )

                        if let progress = selectedTopicProgress {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mayor nivel alcanzado: \(progress.highestDifficulty.title)")
                                    .font(.subheadline)
                                Text("Errores acumulados: \(progress.incorrectAnswers)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button("Iniciar sesion") {
                            startSession(strategy: .standard)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.launchTint)
                        .disabled(filteredQuestions.isEmpty)
                    }

                    SurfaceCard(tint: Color(red: 0.86, green: 0.43, blue: 0.20)) {
                        SectionTitleView(
                            title: "Repasar errores",
                            subtitle: "Usa tus fallos reales como combustible para recordar mejor."
                        )

                        Text("\(recentMistakesCount) preguntas marcadas como fallo reciente en este tema.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Lanzar repaso de errores") {
                            startSession(strategy: .recentMistakes)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.86, green: 0.43, blue: 0.20))
                        .disabled(recentMistakesCount == 0)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitleView(
                            title: "Vista previa",
                            subtitle: "Una muestra rapida del contenido te ayuda a decidir si este es el repaso adecuado."
                        )

                        ForEach(filteredQuestions.prefix(3)) { question in
                            SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
                                Text(question.prompt)
                                    .font(.headline)
                                Text(question.explanation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    CapsuleTag(title: question.mode.title, tint: viewModel.selectedSystem.tintColor)
                                    CapsuleTag(title: question.difficulty.title, tint: viewModel.selectedSystem.tintColor)
                                }
                            }
                        }
                    }

                    if !store.loadIssues.isEmpty {
                        SurfaceCard(tint: .red) {
                            SectionTitleView(
                                title: "Diagnostico de datos",
                                subtitle: "Solo visible aqui para acelerar debug y mantenimiento del catalogo."
                            )

                            ForEach(store.loadIssues) { issue in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(issue.source.capitalized)
                                        .font(.caption.weight(.semibold))
                                    Text(issue.message)
                                        .font(.footnote)
                                        .foregroundStyle(issue.severity == .error ? .red : .secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color(red: 0.95, green: 0.97, blue: 0.96))
            .navigationTitle("Quiz")
            .navigationDestination(item: $activeDraft) { draft in
                QuizSessionView(
                    draft: draft,
                    followUpRecommendation: store.followUpRecommendation(after:),
                    onFinish: handleSessionFinished,
                    onPause: handleSessionPaused,
                    onPersist: handleSessionPersisted
                )
            }
            .alert(item: $alertState) { state in
                Alert(
                    title: Text(state.title),
                    message: Text(state.message),
                    dismissButton: .default(Text("Cerrar"))
                )
            }
            .onAppear {
                restorePersistedDraftIfNeeded()
                applyPendingRequest()
            }
            .onChange(of: pendingRequest?.id) { _, _ in
                applyPendingRequest()
            }
        }
    }

    private func handleSessionFinished(_ result: QuizSessionResult, nextRequest: QuizSessionRequest?) {
        do {
            try progressRecorder.record(
                result: result,
                in: modelContext,
                existingEntries: progressEntries,
                existingHistories: questionHistories
            )
            activeDraft = nil
            resumableDraft = nil
            draftStore.clear()
            if let nextRequest {
                startSession(with: nextRequest)
            }
        } catch {
            alertState = QuizHubAlertState(
                title: "No se pudo guardar el progreso",
                message: error.localizedDescription
            )
        }
    }

    private func handleSessionPaused(_ draft: QuizSessionDraft) {
        resumableDraft = draft
        activeDraft = nil
        draftStore.save(draft)
    }

    private func handleSessionPersisted(_ draft: QuizSessionDraft) {
        resumableDraft = draft
        draftStore.save(draft)
    }

    private func startSession(
        strategy: QuizQuestionSelectionStrategy
    ) {
        startSession(with: viewModel.makeRequest(strategy: strategy))
    }

    private func startSession(with request: QuizSessionRequest) {
        switch store.makeSession(request: request, questionHistories: questionHistories) {
        case .success(let session):
            let draft = QuizSessionDraft(session: session)
            resumableDraft = draft
            activeDraft = draft
            draftStore.save(draft)
        case .failure(let error):
            alertState = QuizHubAlertState(
                title: "No se pudo iniciar la sesion",
                message: error.localizedDescription
            )
        }
    }

    private func applyPendingRequest() {
        guard let request = pendingRequest else { return }
        if viewModel.applyPendingRequest(request) {
            if request.launchBehavior == .autoStart {
                startSession(with: request)
            }
            self.pendingRequest = nil
        }
    }

    private func restorePersistedDraftIfNeeded() {
        guard !hasRestoredPersistedDraft else { return }
        hasRestoredPersistedDraft = true

        guard resumableDraft == nil, let draft = draftStore.load() else { return }
        resumableDraft = draft
        viewModel.apply(draft: draft)
    }

    private var heroSection: some View {
        DashboardHeaderCard(
            eyebrow: "Practica",
            title: selectedTopic.title,
            subtitle: viewModel.heroSubtitle(questionCount: filteredQuestions.count)
        ) {
            HStack(spacing: 12) {
                CapsuleTag(title: "\(filteredQuestions.count) preguntas", tint: .white)
                CapsuleTag(title: viewModel.selectedDifficulty.title, tint: .white)
                CapsuleTag(title: viewModel.selectedPresentationMode.title, tint: .white)
            }
        }
    }

    private var configurationSection: some View {
        SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
            SectionTitleView(
                title: "Configura tu sesion",
                subtitle: "Menos friccion al empezar, mas claridad en lo que vas a practicar."
            )

            systemFilterRow
            modeFilterRow
            difficultyFilterRow
            sessionLengthRow
            presentationModeRow
        }
    }

    private var topicCollectionsSection: some View {
        SurfaceCard(tint: viewModel.selectedSystem.tintColor) {
            SectionTitleView(
                title: "Colecciones inteligentes",
                subtitle: "Cambia de query sin perder contexto: nuevos temas, reforzar, dominados o errores recientes."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TopicCollectionFilter.allCases) { filter in
                        FilterPill(
                            title: filter.title,
                            isSelected: viewModel.selectedCollectionFilter == filter,
                            tint: viewModel.selectedSystem.tintColor
                        ) {
                            viewModel.selectedCollectionFilter = filter
                            applyTopicCollection(filter)
                        }
                    }
                }
            }

            if !relatedTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(relatedTopics) { topic in
                            FilterPill(
                                title: topic.title,
                                isSelected: topic == selectedTopic,
                                tint: topic.system.tintColor
                            ) {
                                apply(topic: topic)
                            }
                        }
                    }
                }
            } else {
                Text("No hay temas disponibles para esta coleccion ahora mismo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var systemFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.systems) { system in
                    FilterChip(
                        title: system.title,
                        isSelected: viewModel.selectedSystem == system,
                        tint: system.tintColor
                    ) {
                        viewModel.selectedSystem = system
                    }
                }
            }
        }
    }

    private var modeFilterRow: some View {
        HStack(spacing: 10) {
            ForEach(QuizMode.allCases) { mode in
                FilterChip(
                    title: mode.title,
                    isSelected: viewModel.selectedMode == mode,
                    tint: viewModel.selectedSystem.tintColor
                ) {
                    viewModel.selectedMode = mode
                }
            }
        }
    }

    private var difficultyFilterRow: some View {
        HStack(spacing: 10) {
            ForEach(DifficultyLevel.allCases) { difficulty in
                FilterChip(
                    title: difficulty.title,
                    isSelected: viewModel.selectedDifficulty == difficulty,
                    tint: viewModel.selectedSystem.tintColor
                ) {
                    viewModel.selectedDifficulty = difficulty
                }
            }
        }
    }

    private var sessionLengthRow: some View {
        HStack(spacing: 10) {
            ForEach(QuizSessionLength.allCases) { length in
                FilterPill(
                    title: length.title,
                    isSelected: viewModel.selectedSessionLength == length,
                    tint: viewModel.selectedSystem.tintColor
                ) {
                    viewModel.selectedSessionLength = length
                }
            }
        }
    }

    private var presentationModeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitleView(
                title: "Experiencia",
                subtitle: "Elige entre refuerzo inmediato o simulacion de examen."
            )

            HStack(spacing: 10) {
                ForEach([QuizPresentationMode.practice, .exam], id: \.rawValue) { mode in
                    FilterPill(
                        title: mode.title,
                        isSelected: viewModel.selectedPresentationMode == mode,
                        tint: mode == .exam ? .black : viewModel.selectedSystem.tintColor
                    ) {
                        viewModel.selectedPresentationMode = mode
                    }
                }
            }

            Text(viewModel.selectedPresentationMode.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func applyTopicCollection(_ filter: TopicCollectionFilter) {
        viewModel.selectedCollectionFilter = filter
        viewModel.applyTopicCollectionCandidate(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    private func apply(topic: QuizTopic) {
        viewModel.apply(topic: topic)
    }
}

#Preview {
    QuizHubView(store: DosifyStore())
        .modelContainer(for: [UserProgress.self, FavoriteDrug.self, QuestionHistory.self], inMemory: true)
}

private struct QuizHubAlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? tint : tint.opacity(0.1),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
