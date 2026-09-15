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
        guard
            days >= 0,
            let endDate = calendar.date(
                byAdding: .day,
                value: days,
                to: calendar.startOfDay(for: referenceDate)
            )
        else {
            return UpcomingChargesSummary(
                total: .zero,
                chargeCount: 0
            )
        }

        let startDate = calendar.startOfDay(
            for: referenceDate
        )
        let inclusiveEndDate = calendar.startOfDay(
            for: endDate
        )

        var total = Decimal.zero
        var chargeCount = 0
        var monthCursor = startDate

        while monthCursor <= inclusiveEndDate {
            for subscription in subscriptions {
                let renewalDates =
                    RenewalCalendarCalculator.scheduledRenewalDates(
                        for: subscription,
                        inMonthContaining: monthCursor,
                        calendar: calendar
                    )

                for renewalDate in renewalDates {
                    let renewalDay = calendar.startOfDay(
                        for: renewalDate
                    )

                    guard
                        renewalDay >= startDate,
                        renewalDay <= inclusiveEndDate
                    else {
                        continue
                    }

                    chargeCount += 1
                    total += subscription.price
                }
            }

            guard
                let monthStart = calendar.dateInterval(
                    of: .month,
                    for: monthCursor
                )?.start,
                let nextMonth = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: monthStart
                )
            else {
                break
            }

            monthCursor = nextMonth
        }

        return UpcomingChargesSummary(
            total: total,
            chargeCount: chargeCount
        )
    }
}
