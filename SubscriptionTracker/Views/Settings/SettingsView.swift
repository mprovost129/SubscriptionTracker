import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers
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
    @State private var showingImportPicker = false
    @State private var pendingImport: SubscriptionCSVImportResult?
    @State private var showingImportConfirmation = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingImportSuccess = false
    @State private var importSuccessMessage = ""
    
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
            ForEach(
                AppSettings.supportedReminderDays,
                id: \.self
            ) { days in
                Text(
                    AppSettings.reminderTimingText(
                        for: days
                    )
                )
                .tag(days)
            }
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

                Button {
                    showingImportPicker = true
                } label: {
                    Label(
                        "Import Subscription Data",
                        systemImage: "square.and.arrow.down"
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .fontWeight(.semibold)

                Text(
                    "Export creates a CSV copy you can save or share. Import supports current and older PDP Subscription Tracker CSV exports. Price history is not included in CSV backup or restore."
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
        .onAppear {
            reminderDaysBefore =
                AppSettings.normalizedReminderDays(
                    reminderDaysBefore
                )
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await refreshNotificationStatus()
                }
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [
                .commaSeparatedText,
                .plainText
            ],
            allowsMultipleSelection: false,
            onCompletion: handleImportSelection
        )
        .confirmationDialog(
            "Import Subscription Data",
            isPresented: $showingImportConfirmation,
            titleVisibility: .visible
        ) {
            if importDuplicateCount > 0 {
                Button("Skip Matches") {
                    performImport(policy: .skip)
                }

                Button("Replace Matches") {
                    performImport(policy: .replace)
                }

                Button("Import All") {
                    performImport(policy: .importAll)
                }
            } else {
                Button("Import") {
                    performImport(policy: .skip)
                }
            }

            Button("Cancel", role: .cancel) {
                pendingImport = nil
            }
        } message: {
            Text(importConfirmationMessage)
        }
        .alert(
            "Import Complete",
            isPresented: $showingImportSuccess
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(importSuccessMessage)
        }
        .alert(
            "Could Not Import Data",
            isPresented: $showingImportError
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(importErrorMessage)
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
            currencyCode: currencyCode,
            includeRestoreMetadata: true
        )

        return SubscriptionCSVFile(
            csv: csv,
            filename:
                SubscriptionCSVExporter.exportFilename()
        )
    }

    private var importDuplicateCount: Int {
        guard let pendingImport else {
            return 0
        }

        return SubscriptionCSVImporter.duplicateCount(
            in: pendingImport,
            existing: subscriptions
        )
    }

    private var importConfirmationMessage: String {
        guard let pendingImport else {
            return ""
        }

        let recordCount = pendingImport.records.count
        let recordText = recordCount == 1
            ? "1 subscription"
            : "\(recordCount) subscriptions"

        var message = "The file contains \(recordText)."

        if importDuplicateCount > 0 {
            let duplicateText = importDuplicateCount == 1
                ? "1 subscription matches existing data."
                : "\(importDuplicateCount) subscriptions match existing data."
            message += " \(duplicateText)"
        }

        if pendingImport.currencyCodes.count == 1,
           let importedCurrency = pendingImport.currencyCodes.first,
           importedCurrency != currencyCode {
            message += " The file uses \(importedCurrency); your app currency will remain \(currencyCode)."
        } else if pendingImport.currencyCodes.count > 1 {
            message += " The file contains multiple currencies; your app currency will remain \(currencyCode)."
        }

        message += " CSV import does not restore price history."

        return message
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

    private func handleImportSelection(
        _ result: Result<[URL], Error>
    ) {
        do {
            let urls = try result.get()

            guard let url = urls.first else {
                return
            }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)

            guard let csv = String(
                data: data,
                encoding: .utf8
            ) else {
                throw SubscriptionCSVImportFileError.notUTF8
            }

            pendingImport = try SubscriptionCSVImporter.parse(
                csv: csv
            )
            showingImportConfirmation = true
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }

    private func performImport(
        policy: SubscriptionCSVImportDuplicatePolicy
    ) {
        guard let pendingImport else {
            return
        }

        var knownSubscriptions = subscriptions
        var affectedSubscriptions: [Subscription] = []
        var importedCount = 0
        var replacedCount = 0
        var skippedCount = 0

        do {
            for record in pendingImport.records {
                let matchingSubscription =
                    SubscriptionCSVImporter.matchingSubscription(
                        for: record,
                        in: knownSubscriptions
                    )

                if let matchingSubscription {
                    switch policy {
                    case .skip:
                        skippedCount += 1
                        continue

                    case .replace:
                        apply(
                            record,
                            to: matchingSubscription
                        )
                        affectedSubscriptions.append(
                            matchingSubscription
                        )
                        replacedCount += 1
                        continue

                    case .importAll:
                        break
                    }
                }

                let newSubscription = subscription(
                    from: record,
                    preserveImportedID: matchingSubscription == nil
                )

                modelContext.insert(newSubscription)
                knownSubscriptions.append(newSubscription)
                affectedSubscriptions.append(newSubscription)
                importedCount += 1
            }

            try modelContext.save()
            self.pendingImport = nil

            importSuccessMessage = importSummary(
                imported: importedCount,
                replaced: replacedCount,
                skipped: skippedCount
            )
            showingImportSuccess = true

            Task {
                await refreshReminders(
                    for: affectedSubscriptions
                )
            }
        } catch {
            modelContext.rollback()
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }

    private func subscription(
        from record: SubscriptionCSVImportRecord,
        preserveImportedID: Bool
    ) -> Subscription {
        let subscription = Subscription(
            name: record.name,
            price: record.price,
            billingFrequency: record.billingFrequency,
            nextBillingDate: record.nextBillingDate,
            trialEndDate: record.trialEndDate,
            category: record.category,
            notes: record.notes,
            managementURL: record.managementURL,
            reminderEnabled: record.reminderEnabled,
            reminderDaysBefore: record.reminderDaysBefore,
            status: record.status,
            cancellationDate: record.cancellationDate
        )

        if preserveImportedID,
           let importedID = record.id {
            subscription.id = importedID
        }

        return subscription
    }

    private func apply(
        _ record: SubscriptionCSVImportRecord,
        to subscription: Subscription
    ) {
        subscription.name = record.name
        subscription.price = record.price
        subscription.billingFrequency = record.billingFrequency
        subscription.nextBillingDate = record.nextBillingDate
        subscription.trialEndDate = record.trialEndDate
        subscription.category = record.category
        subscription.notes = record.notes
        subscription.managementURL = record.managementURL
        subscription.reminderEnabled = record.reminderEnabled
        subscription.reminderDaysBefore = record.reminderDaysBefore
        subscription.status = record.status
        subscription.cancellationDate = record.cancellationDate
        subscription.updatedAt = Date()
    }

    private func importSummary(
        imported: Int,
        replaced: Int,
        skipped: Int
    ) -> String {
        var parts: [String] = []

        if imported > 0 {
            parts.append(
                imported == 1
                    ? "1 subscription imported"
                    : "\(imported) subscriptions imported"
            )
        }

        if replaced > 0 {
            parts.append(
                replaced == 1
                    ? "1 subscription replaced"
                    : "\(replaced) subscriptions replaced"
            )
        }

        if skipped > 0 {
            parts.append(
                skipped == 1
                    ? "1 matching subscription skipped"
                    : "\(skipped) matching subscriptions skipped"
            )
        }

        return parts.isEmpty
            ? "No subscription data changed."
            : parts.joined(separator: ". ") + "."
    }

    private func refreshReminders(
        for subscriptions: [Subscription]
    ) async {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        let canSchedule = switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true
        default:
            false
        }

        for subscription in subscriptions {
            NotificationService.removeRenewalReminder(
                for: subscription
            )

            if canSchedule {
                try? await NotificationService
                    .scheduleRenewalReminder(
                        for: subscription
                    )
            }
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

private enum SubscriptionCSVImportFileError: LocalizedError {
    case notUTF8

    var errorDescription: String? {
        switch self {
        case .notUTF8:
            return "The selected CSV file is not UTF-8 encoded."
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
