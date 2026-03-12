import SwiftUI

struct QuizSessionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: QuizSessionViewModel
    let followUpRecommendation: (QuizSessionResult) -> ReviewRecommendation?
    let onFinish: (QuizSessionResult, QuizSessionRequest?) -> Void
    let onPause: (QuizSessionDraft) -> Void
    let onPersist: (QuizSessionDraft) -> Void

    init(
        session: QuizSession,
        followUpRecommendation: @escaping (QuizSessionResult) -> ReviewRecommendation?,
        onFinish: @escaping (QuizSessionResult, QuizSessionRequest?) -> Void,
        onPause: @escaping (QuizSessionDraft) -> Void,
        onPersist: @escaping (QuizSessionDraft) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: QuizSessionViewModel(session: session)
        )
        self.followUpRecommendation = followUpRecommendation
        self.onFinish = onFinish
        self.onPause = onPause
        self.onPersist = onPersist
    }

    init(
        draft: QuizSessionDraft,
        followUpRecommendation: @escaping (QuizSessionResult) -> ReviewRecommendation?,
        onFinish: @escaping (QuizSessionResult, QuizSessionRequest?) -> Void,
        onPause: @escaping (QuizSessionDraft) -> Void,
        onPersist: @escaping (QuizSessionDraft) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: QuizSessionViewModel(draft: draft)
        )
        self.followUpRecommendation = followUpRecommendation
        self.onFinish = onFinish
        self.onPause = onPause
        self.onPersist = onPersist
    }

    var body: some View {
        NavigationStack {
            if viewModel.isCompleted {
                let result = viewModel.finishResult()
                QuizSessionSummaryView(
                    result: result,
                    recommendation: followUpRecommendation(result),
                    onFinish: { nextRequest in
                        onFinish(result, nextRequest)
                    }
                )
            } else {
                sessionContent
            }
        }
    }

    private var sessionContent: some View {
        let question = viewModel.currentQuestion

        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DashboardHeaderCard(
                    eyebrow: "Sesion activa",
                    title: viewModel.topic.title,
                    subtitle: headerSubtitle
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.progressLabel)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))

                        ProgressView(value: viewModel.sessionProgress)
                            .tint(.white)
                    }
                }

                SurfaceCard(tint: viewModel.topic.system.tintColor) {
                    SectionTitleView(
                        title: "Pregunta",
                        subtitle: questionSectionSubtitle
                    )
                    questionContent(for: question)
                }

                if viewModel.isAnswerSubmitted && viewModel.shouldRevealImmediateFeedback {
                    SurfaceCard(tint: viewModel.submittedAnswer == question.correctAnswer ? .green : .red) {
                        Text(feedbackTitle(for: question))
                            .font(.headline)
                        Text(question.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(red: 0.95, green: 0.97, blue: 0.96))
        .navigationTitle("Sesion")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Salir", role: .cancel) {
                    onPause(viewModel.makeDraft())
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(viewModel.isAnswerSubmitted ? nextButtonTitle : "Comprobar respuesta") {
                if viewModel.isAnswerSubmitted {
                    viewModel.advance()
                } else {
                    viewModel.submitAnswer()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.topic.system.tintColor)
            .disabled(!viewModel.canSubmitAnswer && !viewModel.isAnswerSubmitted)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard !viewModel.isCompleted else { return }
            guard newPhase == .background || newPhase == .inactive else { return }
            onPersist(viewModel.makeDraft())
        }
    }

    private var nextButtonTitle: String {
        viewModel.hasNextQuestion ? "Siguiente pregunta" : "Ver resultado"
    }

    private var headerSubtitle: String {
        switch viewModel.session.presentationMode {
        case .practice:
            return "\(viewModel.topic.subtitle) · Practica con correccion inmediata"
        case .exam:
            return "\(viewModel.topic.subtitle) · Simulacion sin feedback inmediato"
        }
    }

    private var questionSectionSubtitle: String {
        switch viewModel.session.presentationMode {
        case .practice:
            return "Enfoque breve, respuesta clara y feedback inmediato."
        case .exam:
            return "Responde y avanza. La correccion completa aparece al final."
        }
    }

    private func feedbackTitle(for question: Question) -> String {
        viewModel.submittedAnswer == question.correctAnswer ? "Correcto" : "Incorrecto"
    }

    @ViewBuilder
    private func questionContent(for question: Question) -> some View {
        switch question.mode {
        case .matching:
            MatchingQuestionView(
                question: question,
                selectedAnswer: viewModel.selectedAnswer,
                isAnswerSubmitted: viewModel.isAnswerSubmitted,
                onSelectAnswer: selectAnswer,
                answerState: viewModel.answerState(for:)
            )
        case .multipleChoice:
            MultipleChoiceQuestionView(
                question: question,
                selectedAnswer: viewModel.selectedAnswer,
                isAnswerSubmitted: viewModel.isAnswerSubmitted,
                onSelectAnswer: selectAnswer,
                answerState: viewModel.answerState(for:)
            )
        }
    }

    private func selectAnswer(_ answer: String) {
        guard !viewModel.isAnswerSubmitted else { return }
        viewModel.selectedAnswer = answer
    }
}

private struct MultipleChoiceQuestionView: View {
    let question: Question
    let selectedAnswer: String?
    let isAnswerSubmitted: Bool
    let onSelectAnswer: (String) -> Void
    let answerState: (String) -> QuizAnswerState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(.title3.weight(.semibold))

            Text("Elige la respuesta mas correcta entre las opciones disponibles.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(question.options, id: \.self) { option in
                QuizAnswerRow(
                    title: option,
                    subtitle: isAnswerSubmitted && option == question.correctAnswer ? "Respuesta correcta" : nil,
                    isSelected: selectedAnswer == option && !isAnswerSubmitted,
                    state: answerState(option),
                    action: { onSelectAnswer(option) }
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MatchingQuestionView: View {
    let question: Question
    let selectedAnswer: String?
    let isAnswerSubmitted: Bool
    let onSelectAnswer: (String) -> Void
    let answerState: (String) -> QuizAnswerState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Concepto")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(question.prompt)
                    .font(.title3.weight(.semibold))
                Text("Empareja la descripcion con la opcion correcta.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    MatchingOptionCard(
                        title: option,
                        isSelected: selectedAnswer == option && !isAnswerSubmitted,
                        state: answerState(option),
                        action: { onSelectAnswer(option) }
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct QuizAnswerRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let state: QuizAnswerState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    AnswerStateIcon(state: state)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct MatchingOptionCard: View {
    let title: String
    let isSelected: Bool
    let state: QuizAnswerState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    } else {
                        AnswerStateIcon(state: state)
                    }
                }

                Text("Relaciona esta opcion con el concepto mostrado.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }

        switch state {
        case .idle:
            return Color.secondary.opacity(0.08)
        case .correct:
            return Color.green.opacity(0.15)
        case .incorrect:
            return Color.red.opacity(0.12)
        }
    }
}

private struct AnswerStateIcon: View {
    let state: QuizAnswerState

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .incorrect:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

private struct QuizSessionSummaryView: View {
    let result: QuizSessionResult
    let recommendation: ReviewRecommendation?
    let onFinish: (QuizSessionRequest?) -> Void

    var body: some View {
        List {
            DashboardHeaderCard(
                eyebrow: "Resultado",
                title: summaryTitle,
                subtitle: result.presentationMode == .exam
                    ? "Has completado una simulacion de examen. Revisa tus fallos y decide tu siguiente repaso."
                    : "Cada sesion alimenta tu progreso y te ayuda a decidir que repasar despues."
            ) {
                HStack(spacing: 12) {
                    CapsuleTag(title: "\(result.correctAnswers) aciertos", tint: .white)
                    CapsuleTag(title: scoreText, tint: .white)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                MetricTile(title: "Aciertos", value: "\(result.correctAnswers)", symbolName: "checkmark.circle", tint: .green)
                MetricTile(title: "Errores", value: "\(result.incorrectAnswers)", symbolName: "xmark.circle", tint: .red)
                MetricTile(title: "Puntuacion", value: scoreText, symbolName: "scope", tint: result.topic.system.tintColor)
                MetricTile(title: "Nivel", value: result.topic.difficulty.title, symbolName: "flame", tint: .orange)
            }

            SurfaceCard(tint: result.topic.system.tintColor) {
                Text("Tema")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(result.topic.title)
                    .font(.headline)
                Text("Guardar el resultado te permite seguir construyendo progresion por sistema, modo y dificultad.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let recommendation {
                SurfaceCard(tint: result.topic.system.tintColor) {
                    SectionTitleView(
                        title: "Que hacer despues",
                        subtitle: "La salida del quiz debe dejar un siguiente paso claro, no obligarte a decidir desde cero."
                    )

                    Text(recommendation.title)
                        .font(.headline)
                    Text(recommendation.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if result.presentationMode == .exam {
                SurfaceCard(tint: result.topic.system.tintColor) {
                    SectionTitleView(
                        title: "Revision del examen",
                        subtitle: "Los errores se muestran al final para respetar el formato de simulacion."
                    )

                    ForEach(result.reviewItems.filter { !$0.wasCorrect }) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.prompt)
                                .font(.headline)
                            Text("Tu respuesta: \(item.selectedAnswer)")
                                .font(.footnote)
                                .foregroundStyle(.red)
                            Text("Correcta: \(item.correctAnswer)")
                                .font(.footnote.weight(.semibold))
                            Text(item.explanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if result.reviewItems.filter({ !$0.wasCorrect }).isEmpty {
                        Text("No hay errores que revisar en esta simulacion.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.95, green: 0.97, blue: 0.96))
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let recommendation {
                    Button("Guardar y seguir con lo recomendado") {
                        onFinish(recommendation.request)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(result.topic.system.tintColor)
                }

                Button("Guardar progreso y salir") {
                    onFinish(nil)
                }
                .buttonStyle(.bordered)
                .tint(result.topic.system.tintColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Resultado")
    }

    private var scoreText: String {
        let ratio = Double(result.correctAnswers) / Double(max(result.totalQuestions, 1))
        return "\(Int(ratio * 100))%"
    }

    private var summaryTitle: String {
        if result.correctAnswers == result.totalQuestions {
            return result.presentationMode == .exam ? "Examen sobresaliente" : "Sesion perfecta"
        }

        if result.correctAnswers * 2 >= result.totalQuestions {
            return result.presentationMode == .exam ? "Resultado competitivo" : "Buen avance"
        }

        return result.presentationMode == .exam ? "Requiere refuerzo" : "Sigue reforzando"
    }
}
