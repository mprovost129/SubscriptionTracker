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

    var body: some View {
        List(sortedPriceChanges) { change in
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
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .navigationTitle("Price History")
        .navigationBarTitleDisplayMode(.inline)
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

    private func billingDescription(
        for frequency: BillingFrequency
    ) -> String {
        switch frequency {
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        }
    }
}
