import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    let subscription: Subscription
    
    @State private var showingEdit = false
    @State private var showingCancelConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPersistenceError = false
    @State private var persistenceErrorMessage = ""
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyCodeKey)
    
    private var currencyCode = AppSettings.defaultCurrencyCode
    
    private var monthlyEquivalent: Decimal {
        SubscriptionCalculator.monthlyEquivalent(
            price: subscription.price,
            billingFrequency: subscription.billingFrequency
        )
    }

    private var annualEquivalent: Decimal {
        SubscriptionCalculator.annualEquivalent(
            price: subscription.price,
            billingFrequency: subscription.billingFrequency
        )
    }

    private var billingLabel: String {
        switch subscription.billingFrequency {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
    
    private func cancelSubscription() {
        let previousStatus = subscription.status
        let previousCancellationDate = subscription.cancellationDate
        let previousUpdatedAt = subscription.updatedAt

        subscription.status = .canceled
        subscription.cancellationDate = Date()
        subscription.updatedAt = Date()

        do {
            try modelContext.save()

            NotificationService.removeRenewalReminder(
                for: subscription
            )
        } catch {
            subscription.status = previousStatus
            subscription.cancellationDate = previousCancellationDate
            subscription.updatedAt = previousUpdatedAt

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
        }
    }

    private func deleteSubscription() {
        modelContext.delete(subscription)

        do {
            try modelContext.save()

            NotificationService.removeRenewalReminder(
                for: subscription
            )

            dismiss()
        } catch {
            modelContext.rollback()

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
        }
    }
    
    var body: some View {
        Form {
            Section("Subscription") {
                LabeledContent("Name", value: subscription.name)
                
                LabeledContent(
                    "Price",
                    value: subscription.price.formatted(
                        .currency(code: currencyCode)
                    )
                )
                
                LabeledContent(
                    "Billing",
                    value: billingLabel
                )
                
                LabeledContent(
                    "Next Renewal",
                    value: subscription.nextBillingDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                
                LabeledContent(
                    "Status",
                    value: subscription.status == .active
                    ? "Active"
                    : "Canceled"
                )
                
                LabeledContent(
                    "Category",
                    value: subscription.category
                )
            }
            
            Section("Cost") {
                LabeledContent(
                    "Monthly Equivalent",
                    value: monthlyEquivalent.formatted(
                        .currency(code: currencyCode)
                    )
                )
                
                LabeledContent(
                    "Annual Equivalent",
                    value: annualEquivalent.formatted(
                        .currency(code: currencyCode)
                    )
                )
            }
            
            if subscription.status == .active {
                Section("If You Cancel") {
                    LabeledContent(
                        "Monthly Savings",
                        value: monthlyEquivalent.formatted(
                            .currency(code: currencyCode)
                        )
                    )
                    
                    LabeledContent(
                        "Annual Savings",
                        value: annualEquivalent.formatted(
                            .currency(code: currencyCode)
                        )
                    )
                }
            }
            
            Section {
                if !subscription.notes.isEmpty {
                    Section("Notes") {
                        Text(subscription.notes)
                    }
                }
            }
            
            Section {
                if subscription.status == .active {
                    Section {
                        Button("Cancel Subscription", role: .destructive) {
                            showingCancelConfirmation = true
                        }
                    }
                }
                
                Button("Delete Subscription", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
            
            if let cancellationDate = subscription.cancellationDate {
                LabeledContent(
                    "Canceled",
                    value: cancellationDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
            }
        }
        
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditSubscriptionView(
                subscription: subscription
            )
        }
        
        .alert(
            "Cancel \(subscription.name)?",
            isPresented: $showingCancelConfirmation
        ) {
            Button("Cancel Subscription", role: .destructive) {
                cancelSubscription()
            }

            Button("Keep Subscription", role: .cancel) {
                showingCancelConfirmation = false
            }
        } message: {
            Text(
                "This will keep the subscription record but remove it from active spending totals."
            )
        }

        .alert(
            "Delete \(subscription.name)?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete Permanently", role: .destructive) {
                deleteSubscription()
            }

            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = false
            }
        } message: {
            Text(
                "This permanently removes the subscription and cannot be undone."
            )
        }
        
        .alert(
            "Could Not Save Changes",
            isPresented: $showingPersistenceError
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(persistenceErrorMessage)
        }
    }
}
