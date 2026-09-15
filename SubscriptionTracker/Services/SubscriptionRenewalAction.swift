import Foundation
import SwiftData

enum SubscriptionRenewalAction {
    enum RenewalError: LocalizedError {
        case unavailable
        case couldNotCalculateNextDate

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "This subscription cannot be marked as renewed."
            case .couldNotCalculateNextDate:
                return "The next renewal date could not be calculated."
            }
        }
    }

    static func isEligible(
        _ subscription: Subscription,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        subscription.status == .active
        && !SubscriptionTrialCalculator.isActiveTrial(
            subscription,
            on: referenceDate,
            calendar: calendar
        )
    }

    static func isOverdue(
        _ subscription: Subscription,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        isEligible(
            subscription,
            referenceDate: referenceDate,
            calendar: calendar
        )
        && RenewalCalculator.isOverdue(
            subscription,
            from: referenceDate,
            calendar: calendar
        )
    }

    static func nextRenewalDate(
        for subscription: Subscription,
        calendar: Calendar = .current
    ) -> Date? {
        RenewalCalculator.nextRenewalDate(
            after: subscription.nextBillingDate,
            billingFrequency: subscription.billingFrequency,
            calendar: calendar
        )
    }

    @MainActor
    static func markRenewed(
        _ subscription: Subscription,
        modelContext: ModelContext,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) async throws {
        guard isEligible(
            subscription,
            referenceDate: referenceDate,
            calendar: calendar
        ) else {
            throw RenewalError.unavailable
        }

        guard let nextRenewalDate = nextRenewalDate(
            for: subscription,
            calendar: calendar
        ) else {
            throw RenewalError.couldNotCalculateNextDate
        }

        let previousNextBillingDate = subscription.nextBillingDate
        let previousUpdatedAt = subscription.updatedAt

        subscription.nextBillingDate = nextRenewalDate
        subscription.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            subscription.nextBillingDate = previousNextBillingDate
            subscription.updatedAt = previousUpdatedAt
            throw error
        }

        if subscription.reminderEnabled {
            do {
                try await NotificationService.scheduleRenewalReminder(
                    for: subscription,
                    calendar: calendar
                )
            } catch {
                print("Notification error: \(error)")
            }
        } else {
            NotificationService.removeRenewalReminder(
                for: subscription
            )
        }
    }
}
