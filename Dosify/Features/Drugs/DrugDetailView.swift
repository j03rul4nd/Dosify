import OSLog
import SwiftData
import SwiftUI

struct DrugDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteDrug.createdAt, order: .reverse) private var favoriteDrugs: [FavoriteDrug]

    @ObservedObject var store: DosifyStore
    @Binding var selectedTab: RootTab
    @Binding var pendingQuizRequest: QuizSessionRequest?

    let drug: Drug

    @State private var alertState: DrugDetailAlertState?
    @State private var revealedPromptIDs: Set<String> = []

    private var isFavorite: Bool {
        store.isFavorite(drug: drug, favorites: favoriteDrugs)
    }

    private var relatedTopic: QuizTopic? {
        store.practiceTopic(for: drug)
    }

    private var quickFacts: [DrugQuickFact] {
        [
            DrugQuickFact(title: "Sistema", value: drug.system.title, symbolName: drug.system.symbolName),
            DrugQuickFact(title: "Categoria", value: drug.category.title, symbolName: "square.stack.3d.up.fill"),
            DrugQuickFact(title: "Usos", value: "\(drug.uses.count)", symbolName: "cross.case.fill"),
            DrugQuickFact(title: "Claves", value: "\(drug.notes.count)", symbolName: "lightbulb.fill")
        ]
    }

    private var studyPrompts: [StudyPrompt] {
        var prompts: [StudyPrompt] = [
            StudyPrompt(
                id: "system",
                prompt: "Antes de mirar la respuesta, ubica este farmaco dentro del sistema correcto.",
                answer: drug.system.title
            ),
            StudyPrompt(
                id: "mechanism",
                prompt: "Resume en una frase como actua este farmaco.",
                answer: drug.mechanism
            )
        ]

        if let firstUse = drug.uses.first {
            prompts.append(
                StudyPrompt(
                    id: "use",
                    prompt: "Piensa en un escenario clinico donde este farmaco tenga sentido.",
                    answer: firstUse
                )
            )
        }

        if let firstNote = drug.notes.first {
            prompts.append(
                StudyPrompt(
                    id: "note",
                    prompt: "Que detalle no deberias olvidar si esto apareciera en examen o practica?",
                    answer: firstNote
                )
            )
        }

        return prompts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DashboardHeaderCard(
                    eyebrow: drug.system.title,
                    title: drug.name,
                    subtitle: drug.summary
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            CapsuleTag(title: drug.category.title, tint: .white)
                            CapsuleTag(title: isFavorite ? "Guardado" : "Listo para estudiar", tint: .white)
                        }

                        HStack(spacing: 12) {
                            Label("Mecanismo claro", systemImage: "brain.head.profile")
                            Label("Quiz relacionado", systemImage: "bolt.badge.clock")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                    }
                }

                SurfaceCard(tint: drug.system.tintColor) {
                    SectionTitleView(
                        title: "Radar de estudio",
                        subtitle: "Una lectura rapida para orientarte antes de profundizar o practicar."
                    )

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(quickFacts) { fact in
                            MetricTile(
                                title: fact.title,
                                value: fact.value,
                                symbolName: fact.symbolName,
                                tint: drug.system.tintColor
                            )
                        }
                    }
                }

                SurfaceCard(tint: drug.system.tintColor) {
                    SectionTitleView(
                        title: "Mapa mental",
                        subtitle: "Organiza la informacion en bloques que te ayuden a recordar y conectar."
                    )

                    StudySectionCard(
                        title: "Que hace",
                        subtitle: "Idea central para recordar el farmaco cuando vuelvas a verlo.",
                        symbolName: "waveform.path.ecg",
                        tint: drug.system.tintColor,
                        content: drug.mechanism
                    )

                    if !drug.uses.isEmpty {
                        StudyBulletSection(
                            title: "Donde se usa",
                            subtitle: "Relaciona el contenido con contextos clinicos concretos.",
                            symbolName: "cross.case.fill",
                            tint: drug.system.tintColor,
                            items: drug.uses
                        )
                    }

                    if !drug.notes.isEmpty {
                        StudyBulletSection(
                            title: "Que no olvidar",
                            subtitle: "Puntos de seguridad y memoria de alto valor para examen y practica.",
                            symbolName: "exclamationmark.triangle.fill",
                            tint: Color(red: 0.86, green: 0.43, blue: 0.20),
                            items: drug.notes
                        )
                    }
                }

                SurfaceCard(tint: Color(red: 0.43, green: 0.33, blue: 0.73)) {
                    SectionTitleView(
                        title: "Autochequeo",
                        subtitle: "Usa recall activo antes de pasar al quiz. Es la forma mas rapida de detectar huecos."
                    )

                    ForEach(studyPrompts) { prompt in
                        RecallPromptCard(
                            prompt: prompt,
                            isRevealed: revealedPromptIDs.contains(prompt.id),
                            tint: drug.system.tintColor
                        ) {
                            togglePrompt(prompt)
                        }
                    }
                }

                SurfaceCard(tint: drug.system.tintColor) {
                    SectionTitleView(
                        title: "Ruta recomendada",
                        subtitle: "Secuencia breve para estudiar mejor sin saturarte."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        StudyStepRow(
                            index: 1,
                            title: "Haz una lectura rapida",
                            detail: "Interioriza sistema, categoria y mecanismo antes de memorizar detalles.",
                            tint: drug.system.tintColor
                        )
                        StudyStepRow(
                            index: 2,
                            title: "Responde el autochequeo",
                            detail: "Intenta recordar sin mirar para fijar la informacion de forma mas profunda.",
                            tint: drug.system.tintColor
                        )
                        StudyStepRow(
                            index: 3,
                            title: "Pasa a practica inmediata",
                            detail: "Cierra el bucle con preguntas del mismo sistema para consolidar retencion.",
                            tint: drug.system.tintColor
                        )
                    }
                }

                SurfaceCard(tint: drug.system.tintColor) {
                    SectionTitleView(
                        title: "Siguiente accion",
                        subtitle: "Conecta teoria y practica desde la misma pantalla para mejorar retencion."
                    )

                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            toggleFavorite()
                        } label: {
                            Label(
                                isFavorite ? "Quitar favorito" : "Guardar favorito",
                                systemImage: isFavorite ? "heart.slash" : "heart.fill"
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(isFavorite ? .pink : drug.system.tintColor)

                        Button {
                            practiceRelatedTopic()
                        } label: {
                            Label("Practicar ahora", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(drug.system.tintColor)
                        .disabled(relatedTopic == nil)
                    }

                    if let relatedTopic {
                        ActionCard(
                            title: "Practica conectada",
                            subtitle: "Continua con \(relatedTopic.title.lowercased()) para convertir teoria en recuerdo util.",
                            symbolName: "play.circle.fill",
                            tint: drug.system.tintColor,
                            actionTitle: "Abrir quiz relacionado"
                        ) {
                            practiceRelatedTopic()
                        }
                    } else {
                        Text("Todavia no hay quiz disponible para este sistema.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(red: 0.95, green: 0.97, blue: 0.96))
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertState) { state in
            Alert(
                title: Text(state.title),
                message: Text(state.message),
                dismissButton: .default(Text("Cerrar"))
            )
        }
    }

    private func togglePrompt(_ prompt: StudyPrompt) {
        if revealedPromptIDs.contains(prompt.id) {
            revealedPromptIDs.remove(prompt.id)
        } else {
            revealedPromptIDs.insert(prompt.id)
        }
    }

    private func toggleFavorite() {
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
            alertState = DrugDetailAlertState(
                title: "No se pudo actualizar el favorito",
                message: QuizSessionError.favoriteSaveFailed(drugID: drugID).localizedDescription
            )
        }
    }

    private func practiceRelatedTopic() {
        guard let relatedTopic else {
            alertState = DrugDetailAlertState(
                title: "Sin quiz disponible",
                message: "Todavia no hay preguntas configuradas para este sistema."
            )
            return
        }

        pendingQuizRequest = QuizSessionRequest(topic: relatedTopic)
        selectedTab = .quiz
    }
}

private struct DrugDetailAlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct DrugQuickFact: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let symbolName: String
}

private struct StudyPrompt: Identifiable {
    let id: String
    let prompt: String
    let answer: String
}

private struct StudySectionCard: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbolName)
                .font(.headline)
                .foregroundStyle(tint)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct StudyBulletSection: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbolName)
                .font(.headline)
                .foregroundStyle(tint)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(tint)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        Text(item)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct RecallPromptCard: View {
    let prompt: StudyPrompt
    let isRevealed: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt.prompt)
                .font(.headline)
                .foregroundStyle(.primary)

            if isRevealed {
                Text(prompt.answer)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Text("Piensalo unos segundos antes de revelar la respuesta.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(isRevealed ? "Ocultar respuesta" : "Mostrar respuesta", action: action)
                .buttonStyle(.bordered)
                .tint(tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct StudyStepRow: View {
    let index: Int
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
