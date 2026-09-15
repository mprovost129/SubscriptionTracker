import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionRenewalActionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        year: Int = 2026,
        month: Int,
        day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )!
    }

    @Test
    func activePaidSubscriptionIsEligible() {
        let subscription = Subscription(
            name: "Paid",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 1)
        )

        #expect(
            SubscriptionRenewalAction.isEligible(
                subscription,
                referenceDate: date(month: 9, day: 14),
                calendar: calendar
            )
        )
    }

    @Test
    func activeFreeTrialIsNotEligible() {
        let trialEndDate = date(month: 9, day: 20)
        let subscription = Subscription(
            name: "Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )

        #expect(
            !SubscriptionRenewalAction.isEligible(
                subscription,
                referenceDate: date(month: 9, day: 14),
                calendar: calendar
            )
        )
    }

    @Test
    func historicalTrialAfterConversionIsEligible() {
        let subscription = Subscription(
            name: "Converted",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 10),
            trialEndDate: date(month: 8, day: 10)
        )

        #expect(
            SubscriptionRenewalAction.isEligible(
                subscription,
                referenceDate: date(month: 9, day: 14),
                calendar: calendar
            )
        )
    }

    @Test
    func canceledSubscriptionIsNotOverdueEligible() {
        let subscription = Subscription(
            name: "Canceled",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 1),
            status: .canceled
        )

        #expect(
            !SubscriptionRenewalAction.isOverdue(
                subscription,
                referenceDate: date(month: 9, day: 14),
                calendar: calendar
            )
        )
    }

    @Test
    func overduePaidSubscriptionIsDetected() {
        let subscription = Subscription(
            name: "Overdue",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 1)
        )

        #expect(
            SubscriptionRenewalAction.isOverdue(
                subscription,
                referenceDate: date(month: 9, day: 14),
                calendar: calendar
            )
        )
    }

    @Test
    func nextRenewalDateAdvancesOneBillingPeriod() {
        let subscription = Subscription(
            name: "Month End",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(
                year: 2027,
                month: 1,
                day: 31
            )
        )

        let nextDate = SubscriptionRenewalAction.nextRenewalDate(
            for: subscription,
            calendar: calendar
        )

        #expect(nextDate != nil)
        #expect(
            calendar.isDate(
                nextDate!,
                inSameDayAs: date(
                    year: 2027,
                    month: 2,
                    day: 28
                )
            )
        )
    }
}
