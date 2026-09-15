import Foundation
import Testing
@testable import SubscriptionTracker

struct UpcomingChargesCalculatorTests {
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
    func sevenDaySummaryIncludesTodayAndDaySeven() {
        let today = Subscription(
            name: "Today",
            price: Decimal(10),
            billingFrequency: .yearly,
            nextBillingDate: date(month: 9, day: 14)
        )

        let daySeven = Subscription(
            name: "Day Seven",
            price: Decimal(20),
            billingFrequency: .yearly,
            nextBillingDate: date(month: 9, day: 21)
        )

        let dayEight = Subscription(
            name: "Day Eight",
            price: Decimal(40),
            billingFrequency: .yearly,
            nextBillingDate: date(month: 9, day: 22)
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: 7,
            from: [today, daySeven, dayEight],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal(30))
        #expect(summary.chargeCount == 2)
    }

    @Test
    func weeklySubscriptionContributesEveryProjectedCharge() {
        let weekly = Subscription(
            name: "Weekly",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 14)
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: 30,
            from: [weekly],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal(50))
        #expect(summary.chargeCount == 5)
    }

    @Test
    func thirtyDaySummaryProjectsAcrossMonthBoundary() {
        let monthly = Subscription(
            name: "Monthly",
            price: Decimal(25),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 14)
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: 30,
            from: [monthly],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal(50))
        #expect(summary.chargeCount == 2)
    }

    @Test
    func activeTrialFirstChargeIsIncluded() {
        let trialEndDate = date(month: 9, day: 20)
        let trial = Subscription(
            name: "Trial",
            price: Decimal(15),
            billingFrequency: .monthly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: 7,
            from: [trial],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal(15))
        #expect(summary.chargeCount == 1)
    }

    @Test
    func canceledSubscriptionsAreExcluded() {
        let canceled = Subscription(
            name: "Canceled",
            price: Decimal(99),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 14),
            status: .canceled
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: 30,
            from: [canceled],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal.zero)
        #expect(summary.chargeCount == 0)
    }

    @Test
    func negativeWindowReturnsEmptySummary() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 14)
        )

        let summary = UpcomingChargesCalculator.summary(
            withinDays: -1,
            from: [subscription],
            referenceDate: date(month: 9, day: 14),
            calendar: calendar
        )

        #expect(summary.total == Decimal.zero)
        #expect(summary.chargeCount == 0)
    }
}
