import SwiftUI

struct SettingsView: View {
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
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
