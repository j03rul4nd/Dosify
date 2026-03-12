import SwiftData
import SwiftUI

struct ContentView: View {
    @StateObject private var store = DosifyStore()

    var body: some View {
        RootTabView(store: store)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProgress.self, QuestionHistory.self, FavoriteDrug.self], inMemory: true)
}
