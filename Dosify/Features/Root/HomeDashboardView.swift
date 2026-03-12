import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @Query(sort: \UserProgress.lastUpdatedAt, order: .reverse) private var progressEntries: [UserProgress]
    @Query(sort: \QuestionHistory.lastAnsweredAt, order: .reverse) private var questionHistories: [QuestionHistory]
    @Query(sort: \FavoriteDrug.createdAt, order: .reverse) private var favoriteDrugs: [FavoriteDrug]

    @ObservedObject var store: DosifyStore
    @Binding var selectedTab: RootTab
    @Binding var pendingQuizRequest: QuizSessionRequest?

    private var viewModel: HomeDashboardViewModel {
        HomeDashboardViewModel(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories,
            favoriteDrugs: favoriteDrugs
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(viewModel.metricItems) { metric in
                            MetricTile(
                                title: metric.title,
                                value: metric.value,
                                symbolName: metric.symbolName,
                                tint: metric.tint
                            )
                        }
                    }

                    if viewModel.isFirstLaunchExperience {
                        firstRunSection
                    } else {
                        returningFlowSection
                    }

                    if !viewModel.badges.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitleView(
                                title: "Logros activos",
                                subtitle: "Gamificacion ligera para reforzar avance sin saturar la experiencia."
                            )

                            ForEach(viewModel.badges) { badge in
                                SurfaceCard(tint: Color(red: 0.86, green: 0.43, blue: 0.20)) {
                                    HStack(spacing: 14) {
                                        Image(systemName: badge.symbolName)
                                            .font(.title2.weight(.bold))
                                            .foregroundStyle(Color(red: 0.86, green: 0.43, blue: 0.20))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(badge.title)
                                                .font(.headline)
                                            Text(badge.subtitle)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color(red: 0.95, green: 0.97, blue: 0.96))
            .navigationTitle("Inicio")
        }
    }

    private var heroSection: some View {
        DashboardHeaderCard(
            eyebrow: viewModel.heroEyebrow,
            title: viewModel.heroTitle,
            subtitle: viewModel.heroSubtitle
        ) {
            HStack(spacing: 12) {
                Button(viewModel.primaryActionTitle) {
                    if let primaryActionTopic = viewModel.primaryActionTopic {
                        pendingQuizRequest = QuizSessionRequest(topic: primaryActionTopic)
                        selectedTab = .quiz
                    } else {
                        selectedTab = .library
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Color(red: 0.07, green: 0.33, blue: 0.40))

                Button("Explorar biblioteca") {
                    selectedTab = .library
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
    }

    private var firstRunSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitleView(
                title: "Tu primer recorrido",
                subtitle: "La primera apertura debe enseñar la promesa del producto y reducir la friccion del primer avance."
            )

            ActionCard(
                title: "1. Elige un sistema",
                subtitle: "Empieza por el sistema que mas necesites hoy y explora sus farmacos con contexto clinico.",
                symbolName: "cross.case.circle.fill",
                tint: Color(red: 0.14, green: 0.55, blue: 0.50),
                actionTitle: "Explorar sistemas"
            ) {
                selectedTab = .library
            }

            ActionCard(
                title: "2. Haz tu primera practica",
                subtitle: "Convierte la teoria en recuerdo activo con una sesion corta y asumible.",
                symbolName: "bolt.badge.clock.fill",
                tint: Color(red: 0.86, green: 0.43, blue: 0.20),
                actionTitle: "Ir a quiz"
            ) {
                if let recommendedTopic = viewModel.recommendedTopic {
                    pendingQuizRequest = QuizSessionRequest(topic: recommendedTopic)
                }
                selectedTab = .quiz
            }

            SurfaceCard {
                SectionTitleView(
                    title: "Como funciona Dosify",
                    subtitle: "Una promesa clara mejora confianza y hace mas probable la segunda visita."
                )

                LearningPathRow(
                    step: "1",
                    title: "Comprende",
                    subtitle: "Lee un farmaco dentro de su sistema y no como un dato aislado."
                )
                LearningPathRow(
                    step: "2",
                    title: "Recuerda",
                    subtitle: "Practica con sesiones breves y frecuentes para consolidar memoria."
                )
                LearningPathRow(
                    step: "3",
                    title: "Domina",
                    subtitle: "Escala dificultad y usa errores recientes como material de repaso."
                )
            }
        }
    }

    private var returningFlowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let focusTopic = viewModel.focusTopic {
                SurfaceCard(tint: focusTopic.system.tintColor) {
                    SectionTitleView(
                        title: "Tu foco ahora",
                        subtitle: "La home debe responder rapido: que deberia hacer hoy para avanzar."
                    )

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(focusTopic.title)
                                .font(.headline)
                            Text(focusTopic.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(viewModel.focusSupportingText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        CapsuleTag(title: focusTopic.system.title, tint: focusTopic.system.tintColor)
                    }

                    Button("Seguir con este foco") {
                        pendingQuizRequest = QuizSessionRequest(topic: focusTopic)
                        selectedTab = .quiz
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(focusTopic.system.tintColor)
                }
            }

            if let reviewRecommendation = viewModel.reviewRecommendationForToday {
                let reviewTopic = reviewRecommendation.request.topic
                SurfaceCard(tint: reviewTopic.system.tintColor) {
                    SectionTitleView(
                        title: "Repasar hoy",
                        subtitle: "Tu progreso ya sugiere una siguiente accion concreta para mantener retencion."
                    )

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(reviewRecommendation.title)
                                .font(.headline)
                            Text(reviewRecommendation.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        CapsuleTag(title: reviewTopic.system.title, tint: reviewTopic.system.tintColor)
                    }

                    Button("Abrir repaso de hoy") {
                        pendingQuizRequest = reviewRecommendation.request
                        selectedTab = .quiz
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(reviewTopic.system.tintColor)
                }
            }

            HStack(alignment: .top, spacing: 14) {
                ActionCard(
                    title: "Recuperar errores",
                    subtitle: "Usa tus fallos recientes para reforzar memoria de manera mas eficiente.",
                    symbolName: "arrow.trianglehead.counterclockwise",
                    tint: Color(red: 0.86, green: 0.43, blue: 0.20),
                    actionTitle: "Ir al repaso"
                ) {
                    if let focusTopic = viewModel.focusTopic {
                        pendingQuizRequest = QuizSessionRequest(topic: focusTopic)
                    }
                    selectedTab = .quiz
                }

                ActionCard(
                    title: "Volver a favoritos",
                    subtitle: "Retomar contenidos que ya marcaste reduce la friccion de decidir.",
                    symbolName: "heart.circle.fill",
                    tint: Color(red: 0.79, green: 0.24, blue: 0.45),
                    actionTitle: "Abrir biblioteca"
                ) {
                    selectedTab = .library
                }
            }

            ActionCard(
                title: "Ver progreso",
                subtitle: "Abre una vista dedicada con temas fuertes, temas fragiles y repaso pendiente.",
                symbolName: "chart.line.uptrend.xyaxis",
                tint: Color(red: 0.25, green: 0.39, blue: 0.80),
                actionTitle: "Abrir progreso"
            ) {
                selectedTab = .progress
            }
        }
    }
}

private struct LearningPathRow: View {
    let step: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(step)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color(red: 0.07, green: 0.33, blue: 0.40), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
