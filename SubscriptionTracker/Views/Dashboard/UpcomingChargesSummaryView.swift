import SwiftUI

struct UpcomingChargesSummaryView: View {
    let subscriptions: [Subscription]
    let currencyCode: String

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private var nextSevenDays: UpcomingChargesSummary {
        UpcomingChargesCalculator.summary(
            withinDays: 7,
            from: subscriptions
        )
    }

    private var nextThirtyDays: UpcomingChargesSummary {
        UpcomingChargesCalculator.summary(
            withinDays: 30,
            from: subscriptions
        )
    }

    private var summaryLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: 12
                )
            )
        }

        return AnyLayout(
            HStackLayout(
                alignment: .top,
                spacing: 12
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Charges")
                .font(.title2)
                .fontWeight(.semibold)

            summaryLayout {
                summaryCard(
                    title: "Next 7 Days",
                    summary: nextSevenDays
                )

                summaryCard(
                    title: "Next 30 Days",
                    summary: nextThirtyDays
                )
            }

            Text(
                "Projected from active subscriptions and scheduled free-trial conversions."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func summaryCard(
        title: String,
        summary: UpcomingChargesSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(
                summary.total.formatted(
                    .currency(code: currencyCode)
                )
            )
            .font(.title3)
            .fontWeight(.semibold)

            Text(chargeCountText(summary.chargeCount))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        }
        .accessibilityElement(children: .combine)
    }

    private func chargeCountText(_ count: Int) -> String {
        count == 1
            ? "1 projected charge"
            : "\(count) projected charges"
    }
}
