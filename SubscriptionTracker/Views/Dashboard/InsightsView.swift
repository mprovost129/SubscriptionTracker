import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query private var subscriptions: [Subscription]

    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode

    private var categoryInsights:
        [CategorySpendingInsight] {
        SubscriptionInsightsCalculator
            .spendingByCategory(
                for: subscriptions
            )
    }

    private var largestSubscriptions:
        [Subscription] {
        SubscriptionInsightsCalculator
            .largestSubscriptions(
                from: subscriptions
            )
    }

    var body: some View {
        Group {
            if largestSubscriptions.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Active Subscriptions",
                        systemImage: "chart.bar"
                    )
                } description: {
                    Text(
                        "Insights will appear after you add an active subscription."
                    )
                }
            } else {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 28
                    ) {
                        categorySection
                        largestSubscriptionsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Spending by Category")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Active subscriptions ranked by monthly equivalent cost."
            )
            .font(.caption)
            .foregroundStyle(.primary)

            VStack(spacing: 0) {
                ForEach(categoryInsights) { insight in
                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {
                        Text(insight.category)
                            .font(.headline)

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Monthly")
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Text(
                                insight.monthlyCost.formatted(
                                    .currency(
                                        code: currencyCode
                                    )
                                )
                            )
                            .font(.headline)
                            .fontWeight(.semibold)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Yearly")
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Text(
                                insight.annualCost.formatted(
                                    .currency(
                                        code: currencyCode
                                    )
                                )
                            )
                            .font(.headline)
                            .fontWeight(.semibold)
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

                    if insight.id !=
                        categoryInsights.last?.id {
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

    private var largestSubscriptionsSection:
        some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Largest Subscriptions")
                .font(.title2)
                .fontWeight(.semibold)

            Text(
                "Ranked by monthly equivalent cost."
            )
            .font(.caption)
            .foregroundStyle(.primary)

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        largestSubscriptions
                            .enumerated()
                    ),
                    id: \.element.id
                ) { index, subscription in
                    NavigationLink {
                        SubscriptionDetailView(
                            subscription: subscription
                        )
                    } label: {
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(
                                    alignment: .leading,
                                    spacing: 10
                                ) {
                                    Text("Rank \(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Text(subscription.name)
                                        .font(.headline)

                                    Text(subscription.category)
                                        .font(.caption)
                                        .foregroundStyle(.primary)

                                    Text(
                                        SubscriptionCalculator
                                            .monthlyEquivalent(
                                                price:
                                                    subscription.price,
                                                billingFrequency:
                                                    subscription
                                                        .billingFrequency
                                            )
                                            .formatted(
                                                .currency(
                                                    code: currencyCode
                                                )
                                            )
                                    )
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                    Text("per month")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .frame(
                                            width: 28,
                                            alignment: .leading
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
                                        SubscriptionCalculator
                                            .monthlyEquivalent(
                                                price:
                                                    subscription.price,
                                                billingFrequency:
                                                    subscription
                                                        .billingFrequency
                                            )
                                            .formatted(
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
                            alignment: .leading
                        )
                        .padding()
                        .contentShape(Rectangle())
                        .accessibilityElement(
                            children: .combine
                        )
                        .accessibilityLabel(
                            "Rank \(index + 1), \(subscription.name)"
                        )
                        .accessibilityValue(
                            SubscriptionCalculator
                                .monthlyEquivalent(
                                    price:
                                        subscription.price,
                                    billingFrequency:
                                        subscription
                                            .billingFrequency
                                )
                                .formatted(
                                    .currency(
                                        code: currencyCode
                                    )
                                )
                            + " per month"
                        )
                    }
                    .buttonStyle(.plain)

                    if subscription.id !=
                        largestSubscriptions.last?.id {
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

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: Subscription.self,
        inMemory: true
    )
}
