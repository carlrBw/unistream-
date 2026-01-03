import SwiftUI

struct UserSubscriptionCard: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(subscription.service.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subscription.status.rawValue)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                
                Text("Renews \(subscription.renewalDate, format: .dateTime.month().day())")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$\(String(format: "%.2f", subscription.monthlyCost))/month")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            subscription.service.color
                .frame(width: 4)
                .cornerRadius(2)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
    
    private var statusColor: Color {
        switch subscription.status {
        case .active:
            return .green
        case .expired:
            return .red
        case .pending:
            return .yellow
        }
    }
} 
