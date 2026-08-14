import SwiftUI

struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    @State private var name: String
    @State private var price: String
    @State private var billingFrequency: BillingFrequency
    @State private var nextBillingDate: Date
    @State private var category: String
    @State private var notes: String
    @State private var reminderEnabled: Bool

    init(subscription: Subscription) {
        self.subscription = subscription

        _name = State(initialValue: subscription.name)
        _price = State(initialValue: subscription.price.description)
        _billingFrequency = State(initialValue: subscription.billingFrequency)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _category = State(initialValue: subscription.category)
        _notes = State(initialValue: subscription.notes)
        _reminderEnabled = State(initialValue: subscription.reminderEnabled)
    }

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
            .navigationTitle("Edit Subscription")
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
                            await saveChanges()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveChanges() async {
        guard let priceDecimal else {
            return
        }

        subscription.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        subscription.price = priceDecimal
        subscription.billingFrequency = billingFrequency
        subscription.nextBillingDate = nextBillingDate
        subscription.category = category
        subscription.notes = notes
        subscription.reminderEnabled = reminderEnabled
        subscription.updatedAt = Date()
        
        do {
            if reminderEnabled {
                let granted = try await NotificationService.requestAuthorization()

                if granted {
                    try await NotificationService.scheduleRenewalReminder(
                        for: subscription
                    )
                }
            } else {
                NotificationService.removeRenewalReminder(
                    for: subscription
                )
            }
        } catch {
            print("Notification error: \(error)")
        }
        
        dismiss()
    }
}
