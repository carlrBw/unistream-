import SwiftUI

struct Content: Identifiable {
    let id: UUID
    let title: String
    let service: StreamingService
    let category: Category
    let thumbnailURL: String // Changed from thumbnailSystemName
    let bannerURL: String // Added for banner images
    let description: String
    let isTVShow: Bool
    var likes: Int
    var comments: [Comment]
    var episodes: [Episode]?
    var viewCount: Int
    
    init(id: UUID = UUID(), title: String, service: StreamingService, category: Category, thumbnailURL: String, bannerURL: String, description: String, isTVShow: Bool, likes: Int, comments: [Comment], episodes: [Episode]?, viewCount: Int) {
        self.id = id
        self.title = title
        self.service = service
        self.category = category
        self.thumbnailURL = thumbnailURL
        self.bannerURL = bannerURL
        self.description = description
        self.isTVShow = isTVShow
        self.likes = likes
        self.comments = comments
        self.episodes = episodes
        self.viewCount = viewCount
    }
}

struct Episode: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let season: Int
    let episodeNumber: Int
    let likes: Int
    let comments: [Comment]
    let parentContent: Content
}

struct Comment: Identifiable {
    let id: UUID
    let username: String
    let text: String
    let timestamp: Date
    let content: Content
    
    init(id: UUID = UUID(), username: String, text: String, timestamp: Date, content: Content) {
        self.id = id
        self.username = username
        self.text = text
        self.timestamp = timestamp
        self.content = content
    }
}

struct Subscription: Identifiable {
    let id: UUID
    let service: StreamingService
    let status: SubscriptionStatus
    let renewalDate: Date
    let monthlyCost: Double
    
    init(id: UUID = UUID(), service: StreamingService, status: SubscriptionStatus, renewalDate: Date, monthlyCost: Double) {
        self.id = id
        self.service = service
        self.status = status
        self.renewalDate = renewalDate
        self.monthlyCost = monthlyCost
    }
}

enum SubscriptionStatus: String {
    case active = "Active"
    case expired = "Expired"
    case pending = "Pending"
}

enum Category: String, CaseIterable {
    case all = "All"
    case action = "Action"
    case drama = "Drama"
    case comedy = "Comedy"
    case scifi = "Sci-Fi"
    case horror = "Horror"
    case documentary = "Documentary"
    case kids = "Kids"
}

// MARK: - Codable Wrappers
struct CodableContent: Codable {
    let id: UUID
    let title: String
    let service: String
    let category: String
    let thumbnailURL: String
    let bannerURL: String
    let description: String
    let isTVShow: Bool
    let likes: Int
    let viewCount: Int
}

struct CodableComment: Codable {
    let id: UUID
    let username: String
    let text: String
    let timestamp: Date
    let contentId: UUID
    let contentTitle: String
    let contentThumbnailURL: String
}

struct CodableSubscription: Codable {
    let id: UUID
    let service: String
    let status: String
    let renewalDate: Date
    let monthlyCost: Double
}

// MARK: - Codable Conversion Extensions
extension Content {
    func toCodable() -> CodableContent {
        CodableContent(
            id: id,
            title: title,
            service: service.rawValue,
            category: category.rawValue,
            thumbnailURL: thumbnailURL,
            bannerURL: bannerURL,
            description: description,
            isTVShow: isTVShow,
            likes: likes,
            viewCount: viewCount
        )
    }
    
    init(from codable: CodableContent) {
        self.init(
            id: codable.id,
            title: codable.title,
            service: StreamingService(rawValue: codable.service) ?? .netflix,
            category: Category(rawValue: codable.category) ?? .action,
            thumbnailURL: codable.thumbnailURL,
            bannerURL: codable.bannerURL,
            description: codable.description,
            isTVShow: codable.isTVShow,
            likes: codable.likes,
            comments: [],
            episodes: nil,
            viewCount: codable.viewCount
        )
    }
}

extension Comment {
    func toCodable() -> CodableComment {
        CodableComment(
            id: id,
            username: username,
            text: text,
            timestamp: timestamp,
            contentId: content.id,
            contentTitle: content.title,
            contentThumbnailURL: content.thumbnailURL
        )
    }
    
    init(from codable: CodableComment, content: Content) {
        self.init(
            id: codable.id,
            username: codable.username,
            text: codable.text,
            timestamp: codable.timestamp,
            content: content
        )
    }
    
    // For loading comments without content reference (will need to be reconstructed)
    init?(from codable: CodableComment) {
        // This creates a placeholder - the content should be matched later
        // We'll create a minimal Content placeholder
        let placeholderContent = Content(
            id: codable.contentId,
            title: codable.contentTitle,
            service: .netflix,
            category: .action,
            thumbnailURL: codable.contentThumbnailURL,
            bannerURL: "",
            description: "",
            isTVShow: false,
            likes: 0,
            comments: [],
            episodes: nil,
            viewCount: 0
        )
        self.init(
            id: codable.id,
            username: codable.username,
            text: codable.text,
            timestamp: codable.timestamp,
            content: placeholderContent
        )
    }
} 