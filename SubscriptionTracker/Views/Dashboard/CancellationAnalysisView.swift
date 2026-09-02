import SwiftUI

struct CancellationAnalysisView: View {
    let subscriptions: [Subscription]

    @State
    private var selectedSubscriptionIDs: Set<UUID> = []

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode

    private var activeSubscriptions: [Subscription] {
        subscriptions
            .filter {
                SubscriptionTrialCalculator
                    .isPaidActiveSubscription($0)
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare(
                    $1.name
                ) == .orderedAscending
            }
    }

    private var selectedSubscriptions: [Subscription] {
        activeSubscriptions.filter {
            selectedSubscriptionIDs.contains($0.id)
        }
    }

    private var savingsSummary:
        CancellationSavingsSummary {
        CancellationSavingsCalculator.summary(
            forMonthlyCosts:
                selectedSubscriptions.map {
                    SubscriptionCalculator
                        .monthlyEquivalent(
                            price: $0.price,
                            billingFrequency:
                                $0.billingFrequency
                        )
                }
        )
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                summarySection
                subscriptionSection
            }
            .padding()
        }
        .navigationTitle("Cancellation Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Potential Savings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                summaryRow(
                    title: "Selected",
                    value:
                        "\(savingsSummary.selectedCount)"
                )

                Divider()

                summaryRow(
                    title: "Monthly Savings",
                    value:
                        savingsSummary.monthlySavings
                            .formatted(
                                .currency(
                                    code: currencyCode
                                )
                            )
                )

                Divider()

                summaryRow(
                    title: "Yearly Savings",
                    value:
                        savingsSummary.yearlySavings
                            .formatted(
                                .currency(
                                    code: currencyCode
                                )
                            )
                )
            }
            .background(
                .background,
                in: RoundedRectangle(
                    cornerRadius: 16
                )
            )

            if !selectedSubscriptionIDs.isEmpty {
                Button("Clear Selection") {
                    selectedSubscriptionIDs.removeAll()
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .frame(minHeight: 44)
                .accessibilityHint(
                    "Removes all subscriptions from the savings estimate"
                )
            }
        }
    }

    private var subscriptionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Active Subscriptions")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Select subscriptions to estimate how much you could save by canceling them."
            )
            .font(.caption)
            .foregroundStyle(.primary)

            if activeSubscriptions.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Active Subscriptions",
                        systemImage: "checkmark.circle"
                    )
                } description: {
                    Text(
                        "There are no active subscriptions to analyze."
                    )
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(activeSubscriptions) {
                        subscription in
                        subscriptionButton(
                            for: subscription
                        )

                        if subscription.id !=
                            activeSubscriptions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(
                    .background,
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
        }
    }

    private func summaryRow(
        title: String,
        value: String
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Text(title)
                    Text(value)
                        .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value)
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .accessibilityElement(
            children: .combine
        )
    }

    private func subscriptionButton(
        for subscription: Subscription
    ) -> some View {
        let isSelected =
            selectedSubscriptionIDs.contains(
                subscription.id
            )

        let monthlyCost =
            SubscriptionCalculator.monthlyEquivalent(
                price: subscription.price,
                billingFrequency:
                    subscription.billingFrequency
            )

        return Button {
            if isSelected {
                selectedSubscriptionIDs.remove(
                    subscription.id
                )
            } else {
                selectedSubscriptionIDs.insert(
                    subscription.id
                )
            }
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {
                        selectionIndicator(
                            isSelected: isSelected
                        )

                        Text(subscription.name)
                            .font(.headline)

                        Text(subscription.category)
                            .font(.caption)
                            .foregroundStyle(.primary)

                        Text(
                            monthlyCost.formatted(
                                .currency(
                                    code: currencyCode
                                )
                            )
                            + " per month"
                        )
                        .fontWeight(.semibold)
                    }
                } else {
                    HStack(spacing: 12) {
                        selectionIndicator(
                            isSelected: isSelected
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(subscription.name)
                                .font(.headline)

                            Text(subscription.category)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(
                            monthlyCost.formatted(
                                .currency(
                                    code: currencyCode
                                )
                            )
                        )
                        .fontWeight(.semibold)
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 44,
                alignment: .leading
            )
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subscription.name)
        .accessibilityValue(
            monthlyCost.formatted(
                .currency(code: currencyCode)
            )
            + " per month, "
            + (isSelected ? "selected" : "not selected")
        )
        .accessibilityHint(
            isSelected
                ? "Removes this subscription from the analysis"
                : "Adds this subscription to the analysis"
        )
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private func selectionIndicator(
        isSelected: Bool
    ) -> some View {
        Image(
            systemName:
                isSelected
                ? "checkmark.circle.fill"
                : "circle"
        )
        .font(.title2)
        .foregroundStyle(
            isSelected ? Color.accentColor : .primary
        )
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        CancellationAnalysisView(
            subscriptions: []
        )
    }
}
