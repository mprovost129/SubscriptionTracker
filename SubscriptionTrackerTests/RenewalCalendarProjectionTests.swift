import Foundation
import Testing
@testable import SubscriptionTracker

struct RenewalCalendarProjectionTests {
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
    func weeklySubscriptionProjectsEverySevenDaysInMonth() {
        let subscription = Subscription(
            name: "Weekly",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 2)
        )

        let dates = RenewalCalendarCalculator.scheduledRenewalDates(
            for: subscription,
            inMonthContaining: date(month: 9, day: 1),
            calendar: calendar
        )

        let days = dates.map {
            calendar.component(.day, from: $0)
        }

        #expect(days == [2, 9, 16, 23, 30])

        let total = RenewalCalendarCalculator.totalCharges(
            inMonthContaining: date(month: 9, day: 1),
            from: [subscription],
            calendar: calendar
        )

        #expect(total == Decimal(50))
    }

    @Test
    func projectedWeeklyRenewalAppearsOnSelectedDay() {
        let subscription = Subscription(
            name: "Weekly",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 2)
        )

        let result = RenewalCalendarCalculator.activeSubscriptions(
            on: date(month: 9, day: 16),
            from: [subscription],
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Weekly"])
    }

    @Test
    func monthlySubscriptionProjectsIntoFutureMonth() {
        let subscription = Subscription(
            name: "Monthly",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 9, day: 10)
        )

        let result = RenewalCalendarCalculator.activeSubscriptions(
            on: date(month: 10, day: 10),
            from: [subscription],
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Monthly"])
    }

    @Test
    func monthlyProjectionPreservesOriginalMonthEndAnchor() {
        let subscription = Subscription(
            name: "Month End",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: date(
                year: 2027,
                month: 1,
                day: 31
            )
        )

        let februaryDates =
            RenewalCalendarCalculator.scheduledRenewalDates(
                for: subscription,
                inMonthContaining: date(
                    year: 2027,
                    month: 2,
                    day: 1
                ),
                calendar: calendar
            )

        let marchDates =
            RenewalCalendarCalculator.scheduledRenewalDates(
                for: subscription,
                inMonthContaining: date(
                    year: 2027,
                    month: 3,
                    day: 1
                ),
                calendar: calendar
            )

        #expect(
            februaryDates.map {
                calendar.component(.day, from: $0)
            } == [28]
        )
        #expect(
            marchDates.map {
                calendar.component(.day, from: $0)
            } == [31]
        )
    }

    @Test
    func canceledSubscriptionDoesNotProjectRenewals() {
        let subscription = Subscription(
            name: "Canceled",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 2),
            status: .canceled
        )

        let dates = RenewalCalendarCalculator.scheduledRenewalDates(
            for: subscription,
            inMonthContaining: date(month: 9, day: 1),
            calendar: calendar
        )

        #expect(dates.isEmpty)
    }

    @Test
    func projectedDatesDoNotAppearBeforeStoredNextRenewal() {
        let subscription = Subscription(
            name: "Future",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: date(month: 9, day: 10)
        )

        let result = RenewalCalendarCalculator.activeSubscriptions(
            on: date(month: 9, day: 3),
            from: [subscription],
            calendar: calendar
        )

        #expect(result.isEmpty)
    }

    @Test
    func onlyActualTrialEndEventUsesTrialEndLabel() {
        let trialEndDate = date(month: 9, day: 2)
        let subscription = Subscription(
            name: "Weekly Trial",
            price: Decimal(10),
            billingFrequency: .weekly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )

        #expect(
            RenewalCalendarCalculator.isTrialEndEvent(
                subscription,
                on: trialEndDate,
                calendar: calendar
            )
        )

        #expect(
            !RenewalCalendarCalculator.isTrialEndEvent(
                subscription,
                on: date(month: 9, day: 9),
                calendar: calendar
            )
        )
    }
}
