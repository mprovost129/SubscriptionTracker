import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var billingFrequency: BillingFrequency = .monthly
    @State private var nextBillingDate = Date()
    @State private var category = "Other"
    @State private var notes = ""
    @State private var reminderEnabled = true

    private var priceDecimal: Decimal? {
        Decimal(string: price)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && priceDecimal != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    TextField("Name", text: $name)

                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)

                    Picker("Billing", selection: $billingFrequency) {
                        Text("Monthly")
                            .tag(BillingFrequency.monthly)

                        Text("Yearly")
                            .tag(BillingFrequency.yearly)
                    }

                    DatePicker(
                        "Next Billing Date",
                        selection: $nextBillingDate,
                        displayedComponents: .date
                    )
                }

                Section("Details") {
                    TextField("Category", text: $category)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle(
                        "Remind me 3 days before",
                        isOn: $reminderEnabled
                    )
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveSubscription()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveSubscription() async {
        guard let priceDecimal else {
            return
        }

        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceDecimal,
            billingFrequency: billingFrequency,
            nextBillingDate: nextBillingDate,
            category: category,
            notes: notes,
            reminderEnabled: reminderEnabled
        )

        modelContext.insert(subscription)

        if reminderEnabled {
            do {
                let granted = try await NotificationService.requestAuthorization()

                if granted {
                    try await NotificationService.scheduleRenewalReminder(
                        for: subscription
                    )
                }
            } catch {
                print("Notification error: \(error)")
            }
        }

        dismiss()
    }
}

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
