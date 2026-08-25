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
