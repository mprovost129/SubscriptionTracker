import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var subscriptions: [Subscription]
    
    @State private var showingClearDataConfirmation = false
    @State private var showingClearDataError = false
    @State private var clearDataErrorMessage = ""
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode = AppSettings.defaultCurrencyCode
    
    @AppStorage(AppSettings.remindersEnabledByDefaultKey)
    private var remindersEnabledByDefault =
    AppSettings.defaultRemindersEnabled
    
    @AppStorage(AppSettings.reminderDaysBeforeKey)
    private var reminderDaysBefore =
    AppSettings.defaultReminderDaysBefore
    
    var body: some View {
        Form {
            Section("Currency") {
                Picker("Default Currency", selection: $currencyCode) {
                    Text("US Dollar (USD)")
                        .tag("USD")
                    
                    Text("Canadian Dollar (CAD)")
                        .tag("CAD")
                    
                    Text("Euro (EUR)")
                        .tag("EUR")
                    
                    Text("British Pound (GBP)")
                        .tag("GBP")
                }
            }
            
            Section("Renewal Reminders") {
                Toggle(
                    "Enable reminders by default",
                    isOn: $remindersEnabledByDefault
                )
                
                Picker(
                    "Remind me",
                    selection: $reminderDaysBefore
                ) {
                    Text("1 day before")
                        .tag(1)
                    
                    Text("3 days before")
                        .tag(3)
                    
                    Text("7 days before")
                        .tag(7)
                }
                .disabled(!remindersEnabledByDefault)
            }
            
            Section("About") {
                LabeledContent(
                    "App",
                    value: "Subscription Tracker"
                )
                
                LabeledContent(
                    "Version",
                    value: appVersion
                )
                
                NavigationLink("Privacy") {
                    PrivacyView()
                }
            }
            
            Section("Notifications") {
                LabeledContent(
                    "Permission",
                    value: notificationStatusText
                )
                
                if notificationStatus == .denied {
                    Text(
                        "Notifications are turned off in iOS Settings. Subscription Tracker will continue to work, but renewal reminders cannot be delivered."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Button("Open Notification Settings") {
                        openNotificationSettings()
                    }
                }
            }
            
            Section("Data") {
                Button("Clear All Subscription Data", role: .destructive) {
                    showingClearDataConfirmation = true
                }
                .disabled(subscriptions.isEmpty)
            }
        }
        .navigationTitle("Settings")
        .task {
            await refreshNotificationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await refreshNotificationStatus()
                }
            }
        }
        .alert(
            "Clear all subscription data?",
            isPresented: $showingClearDataConfirmation
        ) {
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
            
            Button("Cancel", role: .cancel) {
                showingClearDataConfirmation = false
            }
        } message: {
            Text(
                "This permanently deletes all subscriptions and renewal reminders. Your app settings will be kept."
            )
        }
        
        .alert(
            "Could Not Clear Data",
            isPresented: $showingClearDataError
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(clearDataErrorMessage)
        }
    }
    
    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }
    
    private var notificationStatusText: String {
        switch notificationStatus {
        case .notDetermined:
            return "Not Requested"
        case .denied:
            return "Denied"
        case .authorized:
            return "Allowed"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func clearAllData() {
        do {
            for subscription in subscriptions {
                modelContext.delete(subscription)
            }
            
            try modelContext.save()
            
            NotificationService.removeAllNotifications()
        } catch {
            clearDataErrorMessage = error.localizedDescription
            showingClearDataError = true
        }
    }
    
    private func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openNotificationSettingsURLString
        ) else {
            return
        }
        
        Task {
            await UIApplication.shared.open(url)
        }
    }
    
    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()
        
        notificationStatus = settings.authorizationStatus
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
