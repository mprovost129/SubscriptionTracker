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
        
        let storedReminderDays = UserDefaults.standard.object(
            forKey: AppSettings.reminderDaysBeforeKey
        ) as? Int

        let reminderDaysBeforeRenewal: Int =
            storedReminderDays ?? AppSettings.defaultReminderDaysBefore
        
        // Remove any previously scheduled reminder for this subscription.
        removeRenewalReminder(for: subscription)

        // Find the calendar day three days before renewal.
        guard let reminderDay = calendar.date(
            byAdding: .day,
            value: -reminderDaysBeforeRenewal,
            to: subscription.nextBillingDate
        ) else {
            return
        }

        // Schedule the notification for 9:00 AM on that day.
        var reminderComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: reminderDay
        )

        reminderComponents.hour = 9
        reminderComponents.minute = 0

        // Don't schedule a reminder whose delivery time has already passed.
        guard let actualReminderDate = calendar.date(
            from: reminderComponents
        ),
        actualReminderDate > Date() else {
            return
        }

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
    
    static func printPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current()
            .pendingNotificationRequests()

        print("Pending notifications: \(requests.count)")

        for request in requests {
            print("ID: \(request.identifier)")
            print("Title: \(request.content.title)")
            print("Body: \(request.content.body)")
            print("Trigger: \(String(describing: request.trigger))")
            print("---")
        }
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
