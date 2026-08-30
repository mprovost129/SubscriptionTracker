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

    @Test
    func summaryMeasuresChangeFromFirstPriceToLatestPrice() {
        let firstChange = SubscriptionPriceChange(
            previousPrice: Decimal(10),
            newPrice: Decimal(12),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly,
            changedAt: Date(timeIntervalSince1970: 100)
        )
        let secondChange = SubscriptionPriceChange(
            previousPrice: Decimal(12),
            newPrice: Decimal(15),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly,
            changedAt: Date(timeIntervalSince1970: 200)
        )

        let summary = SubscriptionPriceHistorySummary(
            priceChanges: [firstChange, secondChange]
        )

        #expect(
            summary?.originalMonthlyEquivalent ==
            Decimal(10)
        )
        #expect(
            summary?.currentMonthlyEquivalent ==
            Decimal(15)
        )
        #expect(
            summary?.monthlyEquivalentDifference ==
            Decimal(5)
        )
        #expect(
            summary?.percentageDifference ==
            Decimal(50)
        )
        #expect(summary?.changeCount == 2)
    }

    @Test
    func summarySortsChangesChronologically() {
        let firstChange = SubscriptionPriceChange(
            previousPrice: Decimal(10),
            newPrice: Decimal(12),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly,
            changedAt: Date(timeIntervalSince1970: 100)
        )
        let latestChange = SubscriptionPriceChange(
            previousPrice: Decimal(12),
            newPrice: Decimal(9),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly,
            changedAt: Date(timeIntervalSince1970: 200)
        )

        let summary = SubscriptionPriceHistorySummary(
            priceChanges: [latestChange, firstChange]
        )

        #expect(
            summary?.originalMonthlyEquivalent ==
            Decimal(10)
        )
        #expect(
            summary?.currentMonthlyEquivalent ==
            Decimal(9)
        )
        #expect(
            summary?.monthlyEquivalentDifference ==
            Decimal(-1)
        )
        #expect(
            summary?.percentageDifference ==
            Decimal(-10)
        )
    }

    @Test
    func summaryNormalizesYearlyAndMonthlyPrices() {
        let firstChange = SubscriptionPriceChange(
            previousPrice: Decimal(120),
            newPrice: Decimal(180),
            previousBillingFrequency: .yearly,
            newBillingFrequency: .yearly,
            changedAt: Date(timeIntervalSince1970: 100)
        )
        let latestChange = SubscriptionPriceChange(
            previousPrice: Decimal(180),
            newPrice: Decimal(20),
            previousBillingFrequency: .yearly,
            newBillingFrequency: .monthly,
            changedAt: Date(timeIntervalSince1970: 200)
        )

        let summary = SubscriptionPriceHistorySummary(
            priceChanges: [firstChange, latestChange]
        )

        #expect(
            summary?.originalMonthlyEquivalent ==
            Decimal(10)
        )
        #expect(
            summary?.currentMonthlyEquivalent ==
            Decimal(20)
        )
        #expect(
            summary?.monthlyEquivalentDifference ==
            Decimal(10)
        )
        #expect(
            summary?.percentageDifference ==
            Decimal(100)
        )
    }

    @Test
    func summaryOmitsPercentageForZeroOriginalPrice() {
        let change = SubscriptionPriceChange(
            previousPrice: Decimal(0),
            newPrice: Decimal(10),
            previousBillingFrequency: .monthly,
            newBillingFrequency: .monthly
        )

        let summary = SubscriptionPriceHistorySummary(
            priceChanges: [change]
        )

        #expect(
            summary?.monthlyEquivalentDifference ==
            Decimal(10)
        )
        #expect(summary?.percentageDifference == nil)
        #expect(summary?.changeCount == 1)
    }

    @Test
    func summaryIsNilWithoutPriceChanges() {
        let summary = SubscriptionPriceHistorySummary(
            priceChanges: []
        )

        #expect(summary == nil)
    }
}
