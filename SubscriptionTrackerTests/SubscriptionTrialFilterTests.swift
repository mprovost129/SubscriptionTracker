import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionTrialFilterTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        year: Int = 2026,
        month: Int = 9,
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
    func freeTrialsFilterReturnsOnlyActiveFreeTrials() {
        let referenceDate = date(day: 10)

        let activeTrial = Subscription(
            name: "Active Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 15),
            trialEndDate: date(day: 15)
        )

        let paid = Subscription(
            name: "Paid",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20)
        )

        let expiredTrial = Subscription(
            name: "Expired Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20),
            trialEndDate: date(day: 5)
        )

        let canceledTrial = Subscription(
            name: "Canceled Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 18),
            trialEndDate: date(day: 18),
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [paid, canceledTrial, activeTrial, expiredTrial],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            trialFilter: .freeTrials,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Active Trial"])
    }

    @Test
    func notInFreeTrialIncludesPaidExpiredAndCanceledRecords() {
        let referenceDate = date(day: 10)

        let activeTrial = Subscription(
            name: "Active Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 15),
            trialEndDate: date(day: 15)
        )

        let paid = Subscription(
            name: "Paid",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20)
        )

        let expiredTrial = Subscription(
            name: "Expired Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20),
            trialEndDate: date(day: 5)
        )

        let canceledTrial = Subscription(
            name: "Canceled Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 18),
            trialEndDate: date(day: 18),
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [activeTrial, paid, expiredTrial, canceledTrial],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            trialFilter: .notInFreeTrial,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(
            result.map(\.name) == [
                "Canceled Trial",
                "Expired Trial",
                "Paid"
            ]
        )
    }

    @Test
    func activeStatusAndNotInFreeTrialProducesPaidActiveView() {
        let referenceDate = date(day: 10)

        let activeTrial = Subscription(
            name: "Active Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 15),
            trialEndDate: date(day: 15)
        )

        let paid = Subscription(
            name: "Paid",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20)
        )

        let expiredTrial = Subscription(
            name: "Expired Trial",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20),
            trialEndDate: date(day: 5)
        )

        let canceled = Subscription(
            name: "Canceled",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 20),
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [canceled, activeTrial, paid, expiredTrial],
            statusFilter: .active,
            billingFilter: .all,
            sortOption: .name,
            trialFilter: .notInFreeTrial,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(
            result.map(\.name) == [
                "Expired Trial",
                "Paid"
            ]
        )
    }

    @Test
    func freeTrialFilterCombinesWithNextSevenDays() {
        let referenceDate = date(day: 10)

        let trialSoon = Subscription(
            name: "Trial Soon",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 17),
            trialEndDate: date(day: 17)
        )

        let trialLater = Subscription(
            name: "Trial Later",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 18),
            trialEndDate: date(day: 18)
        )

        let paidSoon = Subscription(
            name: "Paid Soon",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(day: 12)
        )

        let result = SubscriptionListOrganizer.organize(
            [trialLater, paidSoon, trialSoon],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            dateFilter: .next7Days,
            trialFilter: .freeTrials,
            referenceDate: referenceDate,
            calendar: calendar
        )

        #expect(result.map(\.name) == ["Trial Soon"])
    }
}
