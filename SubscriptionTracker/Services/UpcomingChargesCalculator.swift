import Foundation

struct UpcomingChargesSummary: Equatable {
    let total: Decimal
    let chargeCount: Int
}

enum UpcomingChargesCalculator {
    static func summary(
        withinDays days: Int,
        from subscriptions: [Subscription],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> UpcomingChargesSummary {
        guard days >= 0 else {
            return UpcomingChargesSummary(
                total: .zero,
                chargeCount: 0
            )
        }

        let startDate = calendar.startOfDay(
            for: referenceDate
        )

        var total = Decimal.zero
        var chargeCount = 0

        for dayOffset in 0...days {
            guard let date = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: startDate
            ) else {
                continue
            }

            let scheduledSubscriptions =
                RenewalCalendarCalculator.activeSubscriptions(
                    on: date,
                    from: subscriptions,
                    calendar: calendar
                )

            chargeCount += scheduledSubscriptions.count
            total += scheduledSubscriptions.reduce(
                Decimal.zero
            ) { partialTotal, subscription in
                partialTotal + subscription.price
            }
        }

        return UpcomingChargesSummary(
            total: total,
            chargeCount: chargeCount
        )
    }
}
