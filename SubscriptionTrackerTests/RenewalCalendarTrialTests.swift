import Foundation
import Testing
@testable import SubscriptionTracker

struct RenewalCalendarTrialTests {
    @Test
    func expiredTrialCalendarEventRemainsTrialEnd() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let trialEndDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 10
                )
            )
        )

        let subscription = Subscription(
            name: "Trial Service",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )

        #expect(
            RenewalCalendarCalculator.isTrialEndEvent(
                subscription,
                calendar: calendar
            )
        )
    }

    @Test
    func paidRenewalAfterTrialIsNotTrialEndEvent() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let trialEndDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 10
                )
            )
        )

        let paidRenewalDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 10
                )
            )
        )

        let subscription = Subscription(
            name: "Converted Service",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: paidRenewalDate,
            trialEndDate: trialEndDate
        )

        #expect(
            !RenewalCalendarCalculator.isTrialEndEvent(
                subscription,
                calendar: calendar
            )
        )
    }
}
