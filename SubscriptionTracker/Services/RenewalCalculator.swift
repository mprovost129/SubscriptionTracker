import Foundation

struct RenewalCalculator {

    static func daysUntilRenewal(
        for subscription: Subscription,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: date)
        let renewal = calendar.startOfDay(
            for: subscription.nextBillingDate
        )

        return calendar.dateComponents(
            [.day],
            from: start,
            to: renewal
        ).day ?? 0
    }

    static func isDueSoon(
        _ subscription: Subscription,
        withinDays days: Int = 7,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.status == .active else {
            return false
        }

        let daysRemaining = daysUntilRenewal(
            for: subscription,
            from: date,
            calendar: calendar
        )

        return daysRemaining >= 0 && daysRemaining <= days
    }

    static func isOverdue(
        _ subscription: Subscription,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.status == .active else {
            return false
        }

        return daysUntilRenewal(
            for: subscription,
            from: date,
            calendar: calendar
        ) < 0
    }

    static func nextRenewalDate(
        after date: Date,
        billingFrequency: BillingFrequency,
        calendar: Calendar = .current
    ) -> Date? {
        switch billingFrequency {
        case .monthly:
            return calendar.date(
                byAdding: .month,
                value: 1,
                to: date
            )

        case .yearly:
            return calendar.date(
                byAdding: .year,
                value: 1,
                to: date
            )
        }
    }
}
