import Foundation
import UserNotifications

struct NotificationService {
    
    static func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        
        return try await center.requestAuthorization(
            options: [.alert, .sound]
        )
    }
    
    static func scheduleRenewalReminder(
        for subscription: Subscription,
        calendar: Calendar = .current
    ) async throws {
        guard subscription.status == .active,
              subscription.reminderEnabled else {
            removeRenewalReminder(for: subscription)
            return
        }
        
        // Remove any previously scheduled reminder for this subscription.
        removeRenewalReminder(for: subscription)

        guard let actualReminderDate = reminderDeliveryDate(
            for: subscription.nextBillingDate,
            daysBefore: subscription.reminderDaysBefore,
            calendar: calendar
        ),
        actualReminderDate > Date() else {
            return
        }

        let reminderComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: actualReminderDate
        )

        let content = UNMutableNotificationContent()
        content.title = "\(subscription.name) renews soon"
        content.body = renewalMessage(for: subscription)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: reminderComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: subscription),
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }

    static func reminderDeliveryDate(
        for renewalDate: Date,
        daysBefore: Int,
        calendar: Calendar = .current
    ) -> Date? {
        let normalizedDays =
            AppSettings.normalizedReminderDays(
                daysBefore
            )

        guard let reminderDay = calendar.date(
            byAdding: .day,
            value: -normalizedDays,
            to: renewalDate
        ) else {
            return nil
        }

        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: reminderDay
        )

        components.hour = 9
        components.minute = 0

        return calendar.date(from: components)
    }
    
    static func removeRenewalReminder(
        for subscription: Subscription
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    notificationIdentifier(for: subscription)
                ]
            )
    }
    
    static func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()

        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    private static func renewalMessage(
        for subscription: Subscription
    ) -> String {
        let currencyCode = UserDefaults.standard.string(
            forKey: AppSettings.currencyCodeKey
        ) ?? AppSettings.defaultCurrencyCode
        
        let amount = subscription.price.formatted(
            .currency(code: currencyCode)
        )
        
        return "\(amount) is due on \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))."
    }
    
    private static func notificationIdentifier(
        for subscription: Subscription
    ) -> String {
        "renewal-\(subscription.id.uuidString)"
    }
}
