import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let subscription: Subscription

    @State private var name: String
    @State private var price: String
    @State private var billingFrequency: BillingFrequency
    @State private var nextBillingDate: Date
    @State private var category: SubscriptionCategory
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
    @AppStorage(AppSettings.reminderDaysBeforeKey)
    private var reminderDaysBefore =
        AppSettings.defaultReminderDaysBefore
    
    init(subscription: Subscription) {
        self.subscription = subscription

        _name = State(initialValue: subscription.name)
        _price = State(initialValue: subscription.price.description)
        _billingFrequency = State(initialValue: subscription.billingFrequency)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _category = State(
            initialValue:
                SubscriptionCategory(rawValue: subscription.category)
                ?? .other
        )
        _notes = State(initialValue: subscription.notes)
        _reminderEnabled = State(initialValue: subscription.reminderEnabled)
    }

    private var priceDecimal: Decimal? {
        Decimal(string: price)
    }

    private var canSave: Bool {
        guard
            !name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let priceDecimal,
            priceDecimal > 0
        else {
            return false
        }

        return true
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
                    
                    if !price.isEmpty {
                        if let priceDecimal {
                            if priceDecimal <= 0 {
                                Text("Price must be greater than zero.")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Text("Enter a valid price.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle(
                        "Renewal Reminder",
                        isOn: $reminderEnabled
                    )

                    if reminderEnabled {
                        Text(
                            "Reminder will be sent \(reminderDaysBefore) days before renewal."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
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
            .alert(
                "Could Not Save Changes",
                isPresented: $showingSaveError
            ) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text(saveErrorMessage)
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
        subscription.category = category.rawValue
        subscription.notes = notes
        subscription.reminderEnabled = reminderEnabled
        subscription.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
            return
        }
        
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
