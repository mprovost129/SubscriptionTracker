import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    
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

    private var currencyPicker: some View {
        Picker(
            "Default Currency",
            selection: $currencyCode
        ) {
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

    private var reminderTimingPicker: some View {
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
    }
    
    var body: some View {
        Form {
            Section {
                if dynamicTypeSize.isAccessibilitySize {
                    currencyPicker
                        .pickerStyle(.inline)
                } else {
                    currencyPicker
                }
            } header: {
                Text("Currency")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
            
            Section {
                Toggle(
                    "Enable reminders by default",
                    isOn: $remindersEnabledByDefault
                )
                
                if dynamicTypeSize.isAccessibilitySize {
                    reminderTimingPicker
                        .pickerStyle(.inline)
                        .disabled(!remindersEnabledByDefault)
                } else {
                    reminderTimingPicker
                        .disabled(!remindersEnabledByDefault)
                }
            } header: {
                Text("Renewal Reminders")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
            
            Section {
                LabeledContent(
                    "App",
                    value: "PDP Subscription Tracker"
                )
                
                LabeledContent(
                    "Version",
                    value: appVersion
                )
                
                NavigationLink("Privacy") {
                    PrivacyView()
                }
            } header: {
                Text("About")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
            
            Section {
                LabeledContent(
                    "Permission",
                    value: notificationStatusText
                )
                
                if notificationStatus == .denied {
                    Text(
                        "Notifications are turned off in iOS Settings. PDP Subscription Tracker will continue to work, but renewal reminders cannot be delivered."
                    )
                    .font(.caption)
                    .foregroundStyle(.primary)
                    
                    Button("Open Notification Settings") {
                        openNotificationSettings()
                    }
                }
            } header: {
                Text("Notifications")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
            
            Section {
                ShareLink(
                    item: csvExportFile,
                    preview: SharePreview(csvExportFile.filename)
                ) {
                    Label(
                        "Export Subscription Data",
                        systemImage: "square.and.arrow.up"
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .fontWeight(.semibold)
                .disabled(subscriptions.isEmpty)

                Text(
                    "Creates a CSV copy that you can save or share. Your data stays on this device unless you choose to export it."
                )
                .font(.caption)
                .foregroundStyle(.primary)

                Button(
                    "Clear All Subscription Data",
                    role: .destructive
                ) {
                    showingClearDataConfirmation = true
                }
                .font(.title3)
                .fontWeight(.semibold)
                .disabled(subscriptions.isEmpty)
            } header: {
                Text("Data")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
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
    
    private var csvExportFile: SubscriptionCSVFile {
        let csv = SubscriptionCSVExporter.csvString(
            for: subscriptions,
            currencyCode: currencyCode
        )

        return SubscriptionCSVFile(
            csv: csv,
            filename:
                SubscriptionCSVExporter.exportFilename()
        )
    }
    
    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"

        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"

        return "\(version) (\(build))"
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
