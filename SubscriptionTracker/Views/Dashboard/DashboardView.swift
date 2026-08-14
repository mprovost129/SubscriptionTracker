import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSubscription = false
    @State private var showingSettings = false
    @AppStorage(AppSettings.currencyCodeKey)
    
    private var currencyCode = AppSettings.defaultCurrencyCode
    
    private var monthlyTotal: Decimal {
        SubscriptionCalculator.totalMonthlyCost(
            for: subscriptions
        )
    }

    private var annualTotal: Decimal {
        SubscriptionCalculator.totalAnnualCost(
            for: subscriptions
        )
    }
    
    private var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.status == .active }
    }

    private var upcomingSubscriptions: [Subscription] {
        activeSubscriptions.sorted {
            $0.nextBillingDate < $1.nextBillingDate
        }
    }
    
    private var canceledSubscriptions: [Subscription] {
        subscriptions.filter { $0.status == .canceled }
    }
    
    private func renewalStatusText(
        for subscription: Subscription
    ) -> String {
        let days = RenewalCalculator.daysUntilRenewal(
            for: subscription
        )

        if days < 0 {
            let overdueDays = abs(days)

            return overdueDays == 1
                ? "Overdue by 1 day"
                : "Overdue by \(overdueDays) days"
        }

        if days == 0 {
            return "Due Today"
        }

        if days == 1 {
            return "Due Tomorrow"
        }

        return "Due in \(days) days"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(monthlyTotal, format: .currency(code: currencyCode))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yearly")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(annualTotal, format: .currency(code: currencyCode))
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Renewals")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if upcomingSubscriptions.isEmpty {
                            Text("No upcoming renewals yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(upcomingSubscriptions) { subscription in
                                NavigationLink {
                                    SubscriptionDetailView(
                                        subscription: subscription
                                    )
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(
                                                renewalStatusText(
                                                    for: subscription
                                                )
                                            )
                                            .font(.caption)
                                            .fontWeight(.medium)

                                            Text(
                                                subscription.nextBillingDate.formatted(
                                                    date: .abbreviated,
                                                    time: .omitted
                                                )
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(
                                            subscription.price.formatted(
                                                .currency(code: currencyCode)
                                            )
                                        )
                                        .fontWeight(.semibold)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                            }
                        }
                        
                        if !canceledSubscriptions.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Canceled")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                ForEach(canceledSubscriptions) { subscription in
                                    NavigationLink {
                                        SubscriptionDetailView(
                                            subscription: subscription
                                        )
                                    } label: {
                                        HStack {
                                            Text(subscription.name)

                                            Spacer()

                                            Text(
                                                subscription.price.formatted(
                                                    .currency(code: currencyCode)
                                                )
                                            )
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                .padding()
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
