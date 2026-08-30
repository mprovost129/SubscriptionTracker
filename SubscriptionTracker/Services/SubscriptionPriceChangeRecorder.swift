import Foundation

enum SubscriptionPriceChangeRecorder {

    @discardableResult
    static func recordChange(
        for subscription: Subscription,
        newPrice: Decimal,
        newBillingFrequency: BillingFrequency,
        changedAt: Date = Date()
    ) -> Bool {
        let priceChanged =
            subscription.price != newPrice

        let billingFrequencyChanged =
            subscription.billingFrequency !=
            newBillingFrequency

        guard priceChanged ||
                billingFrequencyChanged else {
            return false
        }

        let priceChange = SubscriptionPriceChange(
            previousPrice: subscription.price,
            newPrice: newPrice,
            previousBillingFrequency:
                subscription.billingFrequency,
            newBillingFrequency:
                newBillingFrequency,
            changedAt: changedAt,
            subscription: subscription
        )

        subscription.priceChanges.append(priceChange)

        return true
    }
}
