import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                Text(
                    "PDP Subscription Tracker stores your subscription information locally on this device."
                )

                Text(
                    "PDP Subscription Tracker does not collect, transmit, sell, or share your subscription data."
                )

                Text(
                    "Version 1 does not require an account, server database, bank connection, or cloud synchronization."
                )
            } header: {
                Text("Your Data")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)

            Section {
                Text(
                    "If you enable renewal reminders, PDP Subscription Tracker uses local iOS notifications to remind you about upcoming subscription renewals."
                )
            } header: {
                Text("Notifications")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)

            Section {
                Text(
                    "You can delete individual subscriptions at any time or remove all subscription data from Settings."
                )

                Text(
                    "Deleting PDP Subscription Tracker also removes its locally stored subscription data."
                )
            } header: {
                Text("Data Control")
                    .foregroundStyle(.primary)
            }
            .headerProminence(.increased)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyView()
    }
}
