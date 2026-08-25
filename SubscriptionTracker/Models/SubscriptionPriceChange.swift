import Foundation
import SwiftData

@Model
final class SubscriptionPriceChange {

    var id: UUID = UUID()
    var previousPrice: Decimal
    var newPrice: Decimal
    var previousBillingFrequency: BillingFrequency
    var newBillingFrequency: BillingFrequency
    var changedAt: Date
    var subscription: Subscription?

    var previousMonthlyEquivalent: Decimal {
        SubscriptionCalculator.monthlyEquivalent(
            price: previousPrice,
            billingFrequency: previousBillingFrequency
        )
    }

    var newMonthlyEquivalent: Decimal {
        SubscriptionCalculator.monthlyEquivalent(
            price: newPrice,
            billingFrequency: newBillingFrequency
        )
    }

    var monthlyEquivalentDifference: Decimal {
        newMonthlyEquivalent - previousMonthlyEquivalent
    }

    var percentageDifference: Decimal? {
        guard previousMonthlyEquivalent != 0 else {
            return nil
        }

        return (
            monthlyEquivalentDifference /
            previousMonthlyEquivalent
        ) * 100
    }

    init(
        previousPrice: Decimal,
        newPrice: Decimal,
        previousBillingFrequency: BillingFrequency,
        newBillingFrequency: BillingFrequency,
        changedAt: Date = Date(),
        subscription: Subscription? = nil
    ) {
        self.previousPrice = previousPrice
        self.newPrice = newPrice
        self.previousBillingFrequency =
            previousBillingFrequency
        self.newBillingFrequency =
            newBillingFrequency
        self.changedAt = changedAt
        self.subscription = subscription
    }
}
