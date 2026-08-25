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

struct SubscriptionPriceHistorySummary {

    let originalMonthlyEquivalent: Decimal
    let currentMonthlyEquivalent: Decimal
    let monthlyEquivalentDifference: Decimal
    let percentageDifference: Decimal?
    let changeCount: Int

    init?(priceChanges: [SubscriptionPriceChange]) {
        let sortedChanges = priceChanges.sorted {
            $0.changedAt < $1.changedAt
        }

        guard
            let firstChange = sortedChanges.first,
            let lastChange = sortedChanges.last
        else {
            return nil
        }

        originalMonthlyEquivalent =
            firstChange.previousMonthlyEquivalent
        currentMonthlyEquivalent =
            lastChange.newMonthlyEquivalent
        monthlyEquivalentDifference =
            currentMonthlyEquivalent -
            originalMonthlyEquivalent
        changeCount = sortedChanges.count

        guard originalMonthlyEquivalent != 0 else {
            percentageDifference = nil
            return
        }

        percentageDifference = (
            monthlyEquivalentDifference /
            originalMonthlyEquivalent
        ) * 100
    }
}
