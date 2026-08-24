import Foundation

enum RenewalCalendarCalculator {
    static func days(
        inMonthContaining date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard
            let monthInterval = calendar.dateInterval(
                of: .month,
                for: date
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: date
            )
        else {
            return []
        }

        return dayRange.compactMap { dayOffset in
            calendar.date(
                byAdding: .day,
                value: dayOffset - 1,
                to: monthInterval.start
            )
        }
    }

    static func activeSubscriptions(
        on date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> [Subscription] {
        subscriptions
            .filter { subscription in
                subscription.status == .active
                && calendar.isDate(
                    subscription.nextBillingDate,
                    inSameDayAs: date
                )
            }
            .sorted { first, second in
                let nameComparison =
                    first.name.localizedStandardCompare(
                        second.name
                    )

                if nameComparison == .orderedSame {
                    return first.id.uuidString
                        < second.id.uuidString
                }

                return nameComparison == .orderedAscending
            }
    }

    static func totalCharges(
        on date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Decimal {
        activeSubscriptions(
            on: date,
            from: subscriptions,
            calendar: calendar
        )
        .reduce(Decimal.zero) { total, subscription in
            total + subscription.price
        }
    }

    static func hasRenewals(
        on date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Bool {
        subscriptions.contains { subscription in
            subscription.status == .active
            && calendar.isDate(
                subscription.nextBillingDate,
                inSameDayAs: date
            )
        }
    }
}
