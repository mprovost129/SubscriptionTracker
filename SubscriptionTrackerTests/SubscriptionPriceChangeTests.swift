import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionPriceChangeTests {

    @Test
    func monthlyPriceIncreaseCalculatesImpact() {
        let change = SubscriptionPriceChange(
            previousPrice: Decimal(10),
            newPrice: Decimal(12),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly
        )

        #expect(
            change.previousMonthlyEquivalent ==
            Decimal(10)
        )
        #expect(
            change.newMonthlyEquivalent ==
            Decimal(12)
        )
        #expect(
            change.monthlyEquivalentDifference ==
            Decimal(2)
        )
        #expect(
            change.percentageDifference ==
            Decimal(20)
        )
    }

    @Test
    func billingFrequencyChangeNormalizesImpact() {
        let change = SubscriptionPriceChange(
            previousPrice: Decimal(120),
            newPrice: Decimal(15),
            previousBillingFrequency: .yearly,
            newBillingFrequency: .monthly
        )

        #expect(
            change.previousMonthlyEquivalent ==
            Decimal(10)
        )
        #expect(
            change.newMonthlyEquivalent ==
            Decimal(15)
        )
        #expect(
            change.monthlyEquivalentDifference ==
            Decimal(5)
        )
        #expect(
            change.percentageDifference ==
            Decimal(50)
        )
    }

    @Test
    func equivalentBillingChangeHasZeroImpact() {
        let change = SubscriptionPriceChange(
            previousPrice: Decimal(10),
            newPrice: Decimal(120),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .yearly
        )

        #expect(
            change.monthlyEquivalentDifference ==
            Decimal(0)
        )
        #expect(
            change.percentageDifference ==
            Decimal(0)
        )
    }

    @Test
    func zeroPreviousPriceOmitsPercentage() {
        let change = SubscriptionPriceChange(
            previousPrice: Decimal(0),
            newPrice: Decimal(12),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly
        )

        #expect(
            change.monthlyEquivalentDifference ==
            Decimal(12)
        )
        #expect(change.percentageDifference == nil)
    }
}
