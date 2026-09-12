import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionDateFilterTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var referenceDate: Date {
        calendar.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 2
            )
        )!
    }

    private func date(offsetBy days: Int) -> Date {
        calendar.date(
            byAdding: .day,
            value: days,
            to: referenceDate
        )!
    }

    private func subscription(
        name: String,
        daysFromReference: Int,
        status: SubscriptionStatus = .active,
        trialEndDate: Date? = nil
    ) -> Subscription {
        Subscription(
            name: name,
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(
                offsetBy: daysFromReference
            ),
            trialEndDate: trialEndDate,
            status: status
        )
    }

    @Test
    func overdueFilterReturnsOnlyActiveOverdueSubscriptions() {
        let overdue = subscription(
            name: "Overdue",
            daysFromReference: -1
        )
        let today = subscription(
            name: "Today",
            daysFromReference: 0
        )
        let canceledOverdue = subscription(
            name: "Canceled Overdue",
            daysFromReference: -2,
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [overdue, today, canceledOverdue],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .renewalDate,
            dateFilter: .overdue,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Overdue"])
    }

    @Test
    func nextSevenDaysIncludesTodayAndDaySevenOnly() {
        let overdue = subscription(
            name: "Overdue",
            daysFromReference: -1
        )
        let today = subscription(
            name: "Today",
            daysFromReference: 0
        )
        let daySeven = subscription(
            name: "Day Seven",
            daysFromReference: 7
        )
        let dayEight = subscription(
            name: "Day Eight",
            daysFromReference: 8
        )

        let result = SubscriptionListOrganizer.organize(
            [overdue, today, daySeven, dayEight],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .renewalDate,
            dateFilter: .next7Days,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(
            result.map(\.name) == [
                "Today",
                "Day Seven"
            ]
        )
    }

    @Test
    func nextThirtyDaysIncludesTrialEndingOnDayThirty() {
        let trialEndDate = date(offsetBy: 30)
        let trial = Subscription(
            name: "Trial",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate
        )
        let dayThirtyOne = subscription(
            name: "Day Thirty One",
            daysFromReference: 31
        )

        let result = SubscriptionListOrganizer.organize(
            [trial, dayThirtyOne],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .renewalDate,
            dateFilter: .next30Days,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Trial"])
    }

    @Test
    func allDatesPreservesCanceledSubscriptions() {
        let active = subscription(
            name: "Active",
            daysFromReference: 10
        )
        let canceled = subscription(
            name: "Canceled",
            daysFromReference: 10,
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [active, canceled],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            dateFilter: .all,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(
            result.map(\.name) == [
                "Active",
                "Canceled"
            ]
        )
    }
}
