import SwiftUI

struct SubscriptionPriceHistoryView: View {

    let subscription: Subscription

    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode

    private var sortedPriceChanges: [SubscriptionPriceChange] {
        subscription.priceChanges.sorted {
            $0.changedAt > $1.changedAt
        }
    }

    private var historySummary: SubscriptionPriceHistorySummary? {
        SubscriptionPriceHistorySummary(
            priceChanges: subscription.priceChanges
        )
    }

    var body: some View {
        List {
            if let historySummary {
                Section {
                    summaryRow(
                        title: "Original Monthly",
                        value: currency(
                            historySummary.originalMonthlyEquivalent
                        )
                    )

                    summaryRow(
                        title: "Current Monthly",
                        value: currency(
                            historySummary.currentMonthlyEquivalent
                        )
                    )

                    summaryRow(
                        title: "Net Monthly Change",
                        value: summaryDifference(
                            historySummary
                        )
                    )

                    summaryRow(
                        title: "Recorded Changes",
                        value: historySummary.changeCount.formatted()
                    )
                } header: {
                    Text("Summary")
                        .foregroundStyle(.primary)
                }
                .headerProminence(.increased)
            }

            Section {
                ForEach(sortedPriceChanges) { change in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            change.changedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Previous")

                            Text(
                                priceDescription(
                                    price: change.previousPrice,
                                    frequency:
                                        change.previousBillingFrequency
                                )
                            )
                            .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("New")

                            Text(
                                priceDescription(
                                    price: change.newPrice,
                                    frequency:
                                        change.newBillingFrequency
                                )
                            )
                            .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Impact")

                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 6) {
                                    impactAmount(for: change)
                                    impactPercentage(for: change)
                                }

                                VStack(
                                    alignment: .leading,
                                    spacing: 2
                                ) {
                                    impactAmount(for: change)
                                    impactPercentage(for: change)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("Changes")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
        }
        .navigationTitle("Price History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryRow(
        title: String,
        value: String
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)

                Spacer()

                Text(value)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)

                Text(value)
                    .fontWeight(.semibold)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func summaryDifference(
        _ summary: SubscriptionPriceHistorySummary
    ) -> String {
        let amount = signedCurrency(
            summary.monthlyEquivalentDifference
        )

        guard let percentage = summary.percentageDifference else {
            return amount
        }

        return "\(amount) (\(signedPercentage(percentage)))"
    }

    private func currency(_ value: Decimal) -> String {
        value.formatted(
            .currency(code: currencyCode)
        )
    }

    private func impactAmount(
        for change: SubscriptionPriceChange
    ) -> some View {
        Text(
            signedCurrency(
                change.monthlyEquivalentDifference
            )
        )
        .fontWeight(.semibold)
    }

    @ViewBuilder
    private func impactPercentage(
        for change: SubscriptionPriceChange
    ) -> some View {
        if let percentage = change.percentageDifference {
            Text("(\(signedPercentage(percentage)))")
                .foregroundStyle(.primary)
        }
    }

    private func priceDescription(
        price: Decimal,
        frequency: BillingFrequency
    ) -> String {
        let formattedPrice = price.formatted(
            .currency(code: currencyCode)
        )

        return "\(formattedPrice) \(billingDescription(for: frequency))"
    }

    private func signedCurrency(_ value: Decimal) -> String {
        let magnitude = value < 0 ? -value : value
        let formatted = magnitude.formatted(
            .currency(code: currencyCode)
        )

        if value > 0 {
            return "+\(formatted)"
        }

        if value < 0 {
            return "-\(formatted)"
        }

        return formatted
    }

    private func signedPercentage(_ value: Decimal) -> String {
        let magnitude = value < 0 ? -value : value
        let formatted = NSDecimalNumber(decimal: magnitude)
            .doubleValue
            .formatted(
                .number.precision(
                    .fractionLength(0...1)
                )
            )

        if value > 0 {
            return "+\(formatted)%"
        }

        if value < 0 {
            return "-\(formatted)%"
        }

        return "\(formatted)%"
    }

    private func billingDescription(
        for frequency: BillingFrequency
    ) -> String {
        frequency.lowercaseDisplayName
    }
}
