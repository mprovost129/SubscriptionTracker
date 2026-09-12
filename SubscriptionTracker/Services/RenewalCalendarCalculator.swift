import Foundation

enum RenewalCalendarCalculator {
    private struct ScheduledCharge {
        let subscription: Subscription
        let date: Date
    }

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
                scheduledRenewalDates(
                    for: subscription,
                    inMonthContaining: date,
                    calendar: calendar
                )
                .contains { renewalDate in
                    calendar.isDate(
                        renewalDate,
                        inSameDayAs: date
                    )
                }
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

    static func activeSubscriptions(
        inMonthContaining date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> [Subscription] {
        var seenSubscriptionIDs = Set<UUID>()

        return scheduledCharges(
            inMonthContaining: date,
            from: subscriptions,
            calendar: calendar
        )
        .compactMap { charge in
            guard seenSubscriptionIDs.insert(
                charge.subscription.id
            ).inserted else {
                return nil
            }

            return charge.subscription
        }
    }

    static func scheduledChargeCount(
        inMonthContaining date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Int {
        scheduledCharges(
            inMonthContaining: date,
            from: subscriptions,
            calendar: calendar
        ).count
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

    static func totalCharges(
        inMonthContaining date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Decimal {
        scheduledCharges(
            inMonthContaining: date,
            from: subscriptions,
            calendar: calendar
        )
        .reduce(Decimal.zero) { total, charge in
            total + charge.subscription.price
        }
    }

    static func hasRenewals(
        on date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Bool {
        !activeSubscriptions(
            on: date,
            from: subscriptions,
            calendar: calendar
        ).isEmpty
    }

    static func scheduledRenewalDates(
        for subscription: Subscription,
        inMonthContaining date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard
            subscription.status == .active,
            let monthInterval = calendar.dateInterval(
                of: .month,
                for: date
            )
        else {
            return []
        }

        let anchorDate = subscription.nextBillingDate

        guard anchorDate < monthInterval.end else {
            return []
        }

        var dates: [Date] = []
        var occurrenceIndex = 0

        while occurrenceIndex < 10_000 {
            guard let renewalDate = projectedRenewalDate(
                for: subscription,
                occurrenceIndex: occurrenceIndex,
                calendar: calendar
            ) else {
                break
            }

            if renewalDate >= monthInterval.end {
                break
            }

            if renewalDate >= monthInterval.start {
                dates.append(renewalDate)
            }

            occurrenceIndex += 1
        }

        return dates
    }

    static func isTrialEndEvent(
        _ subscription: Subscription,
        on eventDate: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let trialEndDate = subscription.trialEndDate else {
            return false
        }

        return calendar.isDate(
            eventDate,
            inSameDayAs: trialEndDate
        )
    }

    static func isTrialEndEvent(
        _ subscription: Subscription,
        calendar: Calendar = .current
    ) -> Bool {
        isTrialEndEvent(
            subscription,
            on: subscription.nextBillingDate,
            calendar: calendar
        )
    }

    private static func scheduledCharges(
        inMonthContaining date: Date,
        from subscriptions: [Subscription],
        calendar: Calendar
    ) -> [ScheduledCharge] {
        subscriptions
            .flatMap { subscription in
                scheduledRenewalDates(
                    for: subscription,
                    inMonthContaining: date,
                    calendar: calendar
                )
                .map { renewalDate in
                    ScheduledCharge(
                        subscription: subscription,
                        date: renewalDate
                    )
                }
            }
            .sorted { first, second in
                if first.date != second.date {
                    return first.date < second.date
                }

                let nameComparison =
                    first.subscription.name.localizedStandardCompare(
                        second.subscription.name
                    )

                if nameComparison == .orderedSame {
                    return first.subscription.id.uuidString
                        < second.subscription.id.uuidString
                }

                return nameComparison == .orderedAscending
            }
    }

    private static func projectedRenewalDate(
        for subscription: Subscription,
        occurrenceIndex: Int,
        calendar: Calendar
    ) -> Date? {
        let anchorDate = subscription.nextBillingDate

        guard occurrenceIndex > 0 else {
            return anchorDate
        }

        switch subscription.billingFrequency {
        case .weekly:
            return calendar.date(
                byAdding: .day,
                value: 7 * occurrenceIndex,
                to: anchorDate
            )

        case .monthly:
            return date(
                byAddingMonths: occurrenceIndex,
                to: anchorDate,
                calendar: calendar
            )

        case .quarterly:
            return date(
                byAddingMonths: 3 * occurrenceIndex,
                to: anchorDate,
                calendar: calendar
            )

        case .yearly:
            return date(
                byAddingMonths: 12 * occurrenceIndex,
                to: anchorDate,
                calendar: calendar
            )
        }
    }

    private static func date(
        byAddingMonths monthCount: Int,
        to anchorDate: Date,
        calendar: Calendar
    ) -> Date? {
        let anchorComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: anchorDate
        )

        guard
            let anchorYear = anchorComponents.year,
            let anchorMonth = anchorComponents.month,
            let anchorDay = anchorComponents.day
        else {
            return nil
        }

        var firstOfAnchorMonth = DateComponents()
        firstOfAnchorMonth.year = anchorYear
        firstOfAnchorMonth.month = anchorMonth
        firstOfAnchorMonth.day = 1
        firstOfAnchorMonth.hour = anchorComponents.hour
        firstOfAnchorMonth.minute = anchorComponents.minute
        firstOfAnchorMonth.second = anchorComponents.second

        guard
            let anchorMonthDate = calendar.date(
                from: firstOfAnchorMonth
            ),
            let targetMonthDate = calendar.date(
                byAdding: .month,
                value: monthCount,
                to: anchorMonthDate
            ),
            let targetDayRange = calendar.range(
                of: .day,
                in: .month,
                for: targetMonthDate
            )
        else {
            return nil
        }

        var targetComponents = calendar.dateComponents(
            [.year, .month],
            from: targetMonthDate
        )
        targetComponents.day = min(
            anchorDay,
            targetDayRange.count
        )
        targetComponents.hour = anchorComponents.hour
        targetComponents.minute = anchorComponents.minute
        targetComponents.second = anchorComponents.second

        return calendar.date(from: targetComponents)
    }
}
