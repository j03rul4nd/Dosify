import SwiftUI

struct DashboardHeaderCard<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))

                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.33, blue: 0.40), Color(red: 0.16, green: 0.55, blue: 0.51)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }
}

struct SurfaceCard<Content: View>: View {
    let tint: Color
    @ViewBuilder let content: Content

    init(tint: Color = Color(red: 0.07, green: 0.33, blue: 0.40), @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: tint.opacity(0.08), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(tint.opacity(0.08), lineWidth: 1)
        )
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct CapsuleTag: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct SectionTitleView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isSelected ? tint : Color.white,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: Color
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        SurfaceCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: symbolName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            }
        }
    }
}
