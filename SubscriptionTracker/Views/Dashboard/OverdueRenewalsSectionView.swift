import SwiftUI
import SwiftData

struct OverdueRenewalsSectionView: View {
    let subscriptions: [Subscription]
    let currencyCode: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var pendingRenewal: Subscription?
    @State private var showingRenewalConfirmation = false
    @State private var showingRenewalError = false
    @State private var renewalErrorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Overdue Renewals",
                systemImage: "exclamationmark.circle.fill"
            )
            .font(.title2)
            .fontWeight(.semibold)

            Text(
                "Confirm renewals here after the charge occurs. Each confirmation moves the next renewal date forward by one billing period."
            )
            .font(.caption)
            .foregroundStyle(.primary)

            ForEach(subscriptions) { subscription in
                overdueRow(for: subscription)

                if subscription.id != subscriptions.last?.id {
                    Divider()
                }
            }
        }
        .alert(
            "Mark as Renewed?",
            isPresented: $showingRenewalConfirmation,
            presenting: pendingRenewal
        ) { subscription in
            Button("Mark as Renewed") {
                Task {
                    await markRenewed(subscription)
                }
            }

            Button("Keep Current Date", role: .cancel) {
                pendingRenewal = nil
            }
        } message: { subscription in
            if let nextDate =
                SubscriptionRenewalAction.nextRenewalDate(
                    for: subscription
                ) {
                Text(
                    "\(subscription.name) will move from \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted)) to \(nextDate.formatted(date: .abbreviated, time: .omitted))."
                )
            } else {
                Text(
                    "The next renewal date could not be calculated."
                )
            }
        }
        .alert(
            "Could Not Mark as Renewed",
            isPresented: $showingRenewalError
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(renewalErrorMessage)
        }
    }

    @ViewBuilder
    private func overdueRow(
        for subscription: Subscription
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                subscriptionLink(for: subscription)

                markRenewedButton(for: subscription)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                subscriptionLink(for: subscription)

                markRenewedButton(for: subscription)
            }
        }
    }

    private func subscriptionLink(
        for subscription: Subscription
    ) -> some View {
        NavigationLink {
            SubscriptionDetailView(
                subscription: subscription
            )
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(subscription.name)
                        .font(.headline)

                    Text(overdueStatusText(for: subscription))
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text(
                        subscription.nextBillingDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.primary)
                }

                Spacer()

                Text(
                    subscription.price.formatted(
                        .currency(code: currencyCode)
                    )
                )
                .fontWeight(.semibold)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 44,
                alignment: .leading
            )
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private func markRenewedButton(
        for subscription: Subscription
    ) -> some View {
        Button {
            pendingRenewal = subscription
            showingRenewalConfirmation = true
        } label: {
            Label(
                "Mark Renewed",
                systemImage: "checkmark.circle"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func overdueStatusText(
        for subscription: Subscription
    ) -> String {
        let days = RenewalCalculator.daysUntilRenewal(
            for: subscription
        )
        let overdueDays = abs(days)

        return overdueDays == 1
            ? "Overdue by 1 day"
            : "Overdue by \(overdueDays) days"
    }

    @MainActor
    private func markRenewed(
        _ subscription: Subscription
    ) async {
        do {
            try await SubscriptionRenewalAction.markRenewed(
                subscription,
                modelContext: modelContext
            )
            pendingRenewal = nil
        } catch {
            renewalErrorMessage = error.localizedDescription
            showingRenewalError = true
        }
    }
}
