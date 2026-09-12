import Foundation
import Testing
@testable import SubscriptionTracker

struct RenewalCalendarMonthlyTotalTests {
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
    func monthlyTotalIncludesOnlyChargesInDisplayedMonth() {
        let septemberMonthly = Subscription(
            name: "September Monthly",
            price: Decimal(12),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 5)
        )

        let septemberYearly = Subscription(
            name: "September Yearly",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: date(month: 9, day: 25)
        )

        let october = Subscription(
            name: "October",
            price: Decimal(50),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 1)
        )

        let total = RenewalCalendarCalculator.totalCharges(
            inMonthContaining: date(month: 9, day: 15),
            from: [october, septemberYearly, septemberMonthly],
            calendar: calendar
        )

        #expect(total == Decimal(132))
    }

    @Test
    func monthlyTotalExcludesCanceledSubscriptions() {
        let active = Subscription(
            name: "Active",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 10)
        )

        let canceled = Subscription(
            name: "Canceled",
            price: Decimal(80),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 12),
            status: .canceled
        )

        let total = RenewalCalendarCalculator.totalCharges(
            inMonthContaining: date(month: 9, day: 1),
            from: [active, canceled],
            calendar: calendar
        )

        #expect(total == Decimal(20))
    }

    @Test
    func monthlyTotalIncludesTrialEndingFirstCharge() {
        let trialEndDate = date(month: 9, day: 18)

        let trial = Subscription(
            name: "Trial",
            price: Decimal(15),
            billingFrequency: .monthly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )

        let total = RenewalCalendarCalculator.totalCharges(
            inMonthContaining: date(month: 9, day: 1),
            from: [trial],
            calendar: calendar
        )

        #expect(total == Decimal(15))
    }

    @Test
    func monthlySubscriptionsAreReturnedInDateThenNameOrder() {
        let later = Subscription(
            name: "Later",
            price: Decimal(5),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 20)
        )

        let beta = Subscription(
            name: "Beta",
            price: Decimal(5),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 10)
        )

        let alpha = Subscription(
            name: "Alpha",
            price: Decimal(5),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 10)
        )

        let result = RenewalCalendarCalculator.activeSubscriptions(
            inMonthContaining: date(month: 9, day: 1),
            from: [later, beta, alpha],
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Alpha", "Beta", "Later"])
    }
}
