import SwiftUI

struct SubscriptionsView: View {
    let subscriptions = SubscriptionData.subscriptions
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(subscriptions) { subscription in
                        SubscriptionCard(subscription: subscription)
                    }
                    
                    Button(action: {}) {
                        Text("Manage Subscriptions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(10)
                    }
                    .disabled(true)
                    .overlay(
                        Text("Coming soon")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                    )
                }
                .padding()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
            )
            .navigationTitle("Subscriptions")
        }
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(subscription.service.color)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(subscription.service.rawValue)
                        .font(.headline)
                    Text(subscription.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Renews")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(subscription.renewalDate, style: .date)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Monthly Cost")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", subscription.monthlyCost))")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

#Preview {
    SubscriptionsView()
} 