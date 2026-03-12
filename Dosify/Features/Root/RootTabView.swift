import SwiftData
import SwiftUI

enum RootTab: Hashable {
    case home
    case library
    case quiz
    case progress
}

struct RootTabView: View {
    @ObservedObject var store: DosifyStore
    @State private var selectedTab: RootTab = .home
    @State private var pendingQuizRequest: QuizSessionRequest?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView(
                store: store,
                selectedTab: $selectedTab,
                pendingQuizRequest: $pendingQuizRequest
            )
                .tabItem {
                    Label("Inicio", systemImage: "sparkles.rectangle.stack")
                }
                .tag(RootTab.home)

            DrugLibraryView(
                store: store,
                selectedTab: $selectedTab,
                pendingQuizRequest: $pendingQuizRequest
            )
                .tabItem {
                    Label("Farmacos", systemImage: "cross.case")
                }
                .tag(RootTab.library)

            QuizHubView(store: store, pendingRequest: $pendingQuizRequest)
                .tabItem {
                    Label("Quiz", systemImage: "checklist")
                }
                .tag(RootTab.quiz)

            ProgressOverviewView(
                store: store,
                selectedTab: $selectedTab,
                pendingQuizRequest: $pendingQuizRequest
            )
                .tabItem {
                    Label("Progreso", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(RootTab.progress)
        }
    }
}

#Preview {
    RootTabView(store: DosifyStore())
        .modelContainer(for: [UserProgress.self, FavoriteDrug.self, QuestionHistory.self], inMemory: true)
}
