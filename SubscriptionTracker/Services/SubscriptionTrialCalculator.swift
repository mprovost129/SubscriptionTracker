import Foundation

struct SubscriptionTrialCalculator {

    static func isActive(
        trialEndDate: Date?,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard let trialEndDate else {
            return false
        }

        let currentDay = calendar.startOfDay(for: date)
        let endDay = calendar.startOfDay(
            for: trialEndDate
        )

        return endDay >= currentDay
    }

    static func daysRemaining(
        until trialEndDate: Date?,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let trialEndDate,
              isActive(
                trialEndDate: trialEndDate,
                on: date,
                calendar: calendar
              ) else {
            return nil
        }

        let currentDay = calendar.startOfDay(for: date)
        let endDay = calendar.startOfDay(
            for: trialEndDate
        )

        return calendar.dateComponents(
            [.day],
            from: currentDay,
            to: endDay
        ).day
    }

    static func isActiveTrial(
        _ subscription: Subscription,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.status == .active else {
            return false
        }

        return isActive(
            trialEndDate: subscription.trialEndDate,
            on: date,
            calendar: calendar
        )
    }

    static func isPaidActiveSubscription(
        _ subscription: Subscription,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        subscription.status == .active &&
        !isActiveTrial(
            subscription,
            on: date,
            calendar: calendar
        )
    }
}
