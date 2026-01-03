import Foundation
import SwiftUI

@MainActor
class User: ObservableObject, Identifiable {
    let id: UUID
    let username: String
    let joinDate: Date
    @Published var addedContent: [Content]
    @Published var watchHistory: [Content]
    @Published var activeSubscriptions: [Subscription]
    @Published var comments: [Comment]
    
    init(id: UUID = UUID(), username: String, joinDate: Date, addedContent: [Content], watchHistory: [Content], activeSubscriptions: [Subscription], comments: [Comment]) {
        self.id = id
        self.username = username
        self.joinDate = joinDate
        self.addedContent = addedContent
        self.watchHistory = watchHistory
        self.activeSubscriptions = activeSubscriptions
        self.comments = comments
    }
    
    static let sampleUser = User(
        username: "MovieBuff",
        joinDate: Date().addingTimeInterval(-7776000), // 90 days ago
        addedContent: [],
        watchHistory: [],
        activeSubscriptions: SubscriptionData.subscriptions,
        comments: []
    )
    
    func updateContent(with mockData: MockData) {
        let mandalorian = mockData.content.first { $0.isTVShow }
        let harryPotter = mockData.content.first { !$0.isTVShow }
        
        addedContent = [mandalorian, harryPotter].compactMap { $0 }
        watchHistory = [mandalorian, harryPotter].compactMap { $0 }
        
        if let show = mandalorian, let movie = harryPotter {
            comments = [
                Comment(
                    username: "MovieBuff",
                    text: "This show is amazing!",
                    timestamp: Date().addingTimeInterval(-86400),
                    content: show
                ),
                Comment(
                    username: "MovieBuff",
                    text: "Can't wait for the next movie!",
                    timestamp: Date().addingTimeInterval(-172800),
                    content: movie
                )
            ]
        }
    }
}

// New struct to track user comments with content info
struct UserComment: Identifiable {
    let id = UUID()
    let comment: Comment
    let content: Content
    let episode: Episode?
}

// MARK: - Codable Wrappers
struct CodableUser: Codable {
    let id: UUID
    let username: String
    let joinDate: Date
    let addedContent: [CodableContent]
    let watchHistory: [CodableContent]
    let activeSubscriptions: [CodableSubscription]
    let comments: [CodableComment]
}

// MARK: - Codable Conversion Extensions
extension User {
    func toCodable() -> CodableUser {
        CodableUser(
            id: id,
            username: username,
            joinDate: joinDate,
            addedContent: addedContent.map { $0.toCodable() },
            watchHistory: watchHistory.map { $0.toCodable() },
            activeSubscriptions: activeSubscriptions.map { $0.toCodable() },
            comments: comments.map { $0.toCodable() }
        )
    }
    
    convenience init(from codable: CodableUser) {
        let addedContent = codable.addedContent.map { Content(from: $0) }
        let watchHistory = codable.watchHistory.map { Content(from: $0) }
        let subscriptions = codable.activeSubscriptions.map { Subscription(from: $0) }
        
        // Reconstruct comments with proper content references
        var reconstructedComments: [Comment] = []
        for codableComment in codable.comments {
            // Try to find matching content in addedContent or watchHistory
            if let matchingContent = (addedContent + watchHistory).first(where: { $0.id == codableComment.contentId }) {
                reconstructedComments.append(Comment(from: codableComment, content: matchingContent))
            } else if let comment = Comment(from: codableComment) {
                reconstructedComments.append(comment)
            }
        }
        
        self.init(
            id: codable.id,
            username: codable.username,
            joinDate: codable.joinDate,
            addedContent: addedContent,
            watchHistory: watchHistory,
            activeSubscriptions: subscriptions,
            comments: reconstructedComments
        )
    }
}

extension Subscription {
    func toCodable() -> CodableSubscription {
        CodableSubscription(
            id: id,
            service: service.rawValue,
            status: status.rawValue,
            renewalDate: renewalDate,
            monthlyCost: monthlyCost
        )
    }
    
    init(from codable: CodableSubscription) {
        self.init(
            id: codable.id,
            service: StreamingService(rawValue: codable.service) ?? .netflix,
            status: SubscriptionStatus(rawValue: codable.status) ?? .active,
            renewalDate: codable.renewalDate,
            monthlyCost: codable.monthlyCost
        )
    }
} 
