import SwiftData
import SwiftUI

struct ProgressOverviewView: View {
    @Query(sort: \UserProgress.lastUpdatedAt, order: .reverse) private var progressEntries: [UserProgress]
    @Query(sort: \QuestionHistory.lastAnsweredAt, order: .reverse) private var questionHistories: [QuestionHistory]

    @ObservedObject var store: DosifyStore
    @Binding var selectedTab: RootTab
    @Binding var pendingQuizRequest: QuizSessionRequest?

    private var viewModel: ProgressOverviewViewModel {
        ProgressOverviewViewModel(
            store: store,
            progressEntries: progressEntries,
            questionHistories: questionHistories
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
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

                    dueTodaySection

                    if !viewModel.weakestTopics.isEmpty {
                        topicSection(
                            title: "Necesitan refuerzo",
                            subtitle: "Temas con menor precision o menor consolidacion.",
                            topics: viewModel.weakestTopics,
                            tint: Color(red: 0.86, green: 0.43, blue: 0.20)
                        )
                    }

                    if !viewModel.strongestTopics.isEmpty {
                        topicSection(
                            title: "Mejor dominados",
                            subtitle: "Tus bloques mas fuertes ahora mismo.",
                            topics: viewModel.strongestTopics,
                            tint: Color(red: 0.15, green: 0.53, blue: 0.47)
                        )
                    }

                    if !viewModel.badges.isEmpty {
                        SurfaceCard(tint: Color(red: 0.25, green: 0.39, blue: 0.80)) {
                            SectionTitleView(
                                title: "Logros",
                                subtitle: "Senales ligeras de avance para reforzar continuidad."
                            )

                            ForEach(viewModel.badges) { badge in
                                HStack(spacing: 12) {
                                    Image(systemName: badge.symbolName)
                                        .foregroundStyle(Color(red: 0.25, green: 0.39, blue: 0.80))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(badge.title)
                                            .font(.headline)
                                        Text(badge.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
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
            .navigationTitle("Progreso")
        }
    }

    private var heroSection: some View {
        DashboardHeaderCard(
            eyebrow: "Progreso",
            title: viewModel.hasProgress ? "Tu aprendizaje, visible." : "Empieza a construir progreso.",
            subtitle: viewModel.hasProgress
                ? "Usa esta vista para decidir que repasar hoy, que temas consolidar y donde ya tienes una base fuerte."
                : "Todavia no hay sesiones registradas. Tu progreso empezara a tomar forma en cuanto completes la primera practica."
        ) {
            HStack(spacing: 12) {
                Button(viewModel.dailyReviewPlan.dueTopics.isEmpty ? "Ir a quiz" : "Repasar hoy") {
                    if let recommendation = viewModel.primaryRecommendation {
                        pendingQuizRequest = recommendation.request
                    }
                    selectedTab = .quiz
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

    private var dueTodaySection: some View {
        SurfaceCard(tint: Color(red: 0.42, green: 0.33, blue: 0.75)) {
            SectionTitleView(
                title: viewModel.dueTodayTitle,
                subtitle: viewModel.dueTodaySubtitle
            )

            if let recommendation = viewModel.primaryRecommendation {
                let topic = recommendation.request.topic
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendation.title)
                            .font(.headline)
                        Text(recommendation.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    CapsuleTag(title: topic.system.title, tint: topic.system.tintColor)
                }

                Button("Abrir repaso prioritario") {
                    pendingQuizRequest = recommendation.request
                    selectedTab = .quiz
                }
                .buttonStyle(.borderedProminent)
                .tint(topic.system.tintColor)
            }
        }
    }

    private func topicSection(
        title: String,
        subtitle: String,
        topics: [TopicProgressSnapshot],
        tint: Color
    ) -> some View {
        SurfaceCard(tint: tint) {
            SectionTitleView(title: title, subtitle: subtitle)

            ForEach(topics, id: \.topic.id) { snapshot in
                Button {
                    pendingQuizRequest = QuizSessionRequest(topic: snapshot.topic)
                    selectedTab = .quiz
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(snapshot.topic.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(snapshot.accuracyPercentageText) de precision · \(snapshot.completedSessions) sesiones")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        CapsuleTag(title: snapshot.topic.difficulty.title, tint: snapshot.topic.system.tintColor)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
