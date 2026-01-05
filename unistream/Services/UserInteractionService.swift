import Foundation

@MainActor
class UserInteractionService: ObservableObject {
    static let shared = UserInteractionService()
    
    // Track which users have liked content/episodes
    // Key: Content/Episode ID, Value: Array of User IDs
    @Published private var contentLikes: [UUID: [UUID]] = [:]
    @Published private var episodeLikes: [UUID: [UUID]] = [:]
    
    // Track which users have watched content/episodes
    @Published private var contentViews: [UUID: [UUID]] = [:]
    @Published private var episodeViews: [UUID: [UUID]] = [:]
    
    private let contentLikesKey = "contentLikes"
    private let episodeLikesKey = "episodeLikes"
    private let contentViewsKey = "contentViews"
    private let episodeViewsKey = "episodeViews"
    
    private init() {
        loadData()
    }
    
    // MARK: - Likes
    
    func likeContent(_ contentId: UUID, userId: UUID) {
        if contentLikes[contentId] == nil {
            contentLikes[contentId] = []
        }
        if !contentLikes[contentId]!.contains(userId) {
            contentLikes[contentId]!.append(userId)
            saveContentLikes()
        }
    }
    
    func unlikeContent(_ contentId: UUID, userId: UUID) {
        contentLikes[contentId]?.removeAll(where: { $0 == userId })
        saveContentLikes()
    }
    
    func hasUserLikedContent(_ contentId: UUID, userId: UUID) -> Bool {
        return contentLikes[contentId]?.contains(userId) ?? false
    }
    
    func getContentLikesCount(_ contentId: UUID) -> Int {
        return contentLikes[contentId]?.count ?? 0
    }
    
    func likeEpisode(_ episodeId: UUID, userId: UUID) {
        if episodeLikes[episodeId] == nil {
            episodeLikes[episodeId] = []
        }
        if !episodeLikes[episodeId]!.contains(userId) {
            episodeLikes[episodeId]!.append(userId)
            saveEpisodeLikes()
        }
    }
    
    func unlikeEpisode(_ episodeId: UUID, userId: UUID) {
        episodeLikes[episodeId]?.removeAll(where: { $0 == userId })
        saveEpisodeLikes()
    }
    
    func hasUserLikedEpisode(_ episodeId: UUID, userId: UUID) -> Bool {
        return episodeLikes[episodeId]?.contains(userId) ?? false
    }
    
    func getEpisodeLikesCount(_ episodeId: UUID) -> Int {
        return episodeLikes[episodeId]?.count ?? 0
    }
    
    // MARK: - Views/Watched
    
    func markContentAsWatched(_ contentId: UUID, userId: UUID) {
        if contentViews[contentId] == nil {
            contentViews[contentId] = []
        }
        if !contentViews[contentId]!.contains(userId) {
            contentViews[contentId]!.append(userId)
            saveContentViews()
        }
    }
    
    func unmarkContentAsWatched(_ contentId: UUID, userId: UUID) {
        contentViews[contentId]?.removeAll(where: { $0 == userId })
        saveContentViews()
    }
    
    func hasUserWatchedContent(_ contentId: UUID, userId: UUID) -> Bool {
        return contentViews[contentId]?.contains(userId) ?? false
    }
    
    func getContentViewsCount(_ contentId: UUID) -> Int {
        return contentViews[contentId]?.count ?? 0
    }
    
    func markEpisodeAsWatched(_ episodeId: UUID, userId: UUID) {
        if episodeViews[episodeId] == nil {
            episodeViews[episodeId] = []
        }
        if !episodeViews[episodeId]!.contains(userId) {
            episodeViews[episodeId]!.append(userId)
            saveEpisodeViews()
        }
    }
    
    func unmarkEpisodeAsWatched(_ episodeId: UUID, userId: UUID) {
        episodeViews[episodeId]?.removeAll(where: { $0 == userId })
        saveEpisodeViews()
    }
    
    func hasUserWatchedEpisode(_ episodeId: UUID, userId: UUID) -> Bool {
        return episodeViews[episodeId]?.contains(userId) ?? false
    }
    
    func getEpisodeViewsCount(_ episodeId: UUID) -> Int {
        return episodeViews[episodeId]?.count ?? 0
    }
    
    // MARK: - Persistence
    
    private func saveContentLikes() {
        let dict = contentLikes.mapValues { $0.map { $0.uuidString } }
        UserDefaults.standard.set(dict, forKey: contentLikesKey)
    }
    
    private func saveEpisodeLikes() {
        let dict = episodeLikes.mapValues { $0.map { $0.uuidString } }
        UserDefaults.standard.set(dict, forKey: episodeLikesKey)
    }
    
    private func saveContentViews() {
        let dict = contentViews.mapValues { $0.map { $0.uuidString } }
        UserDefaults.standard.set(dict, forKey: contentViewsKey)
    }
    
    private func saveEpisodeViews() {
        let dict = episodeViews.mapValues { $0.map { $0.uuidString } }
        UserDefaults.standard.set(dict, forKey: episodeViewsKey)
    }
    
    private func loadData() {
        // Load content likes
        if let dict = UserDefaults.standard.dictionary(forKey: contentLikesKey) {
            contentLikes = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                guard let contentId = UUID(uuidString: key),
                      let userIds = value as? [String] else { return nil }
                let uuidArray = userIds.compactMap { UUID(uuidString: $0) }
                return (contentId, uuidArray)
            })
        }
        
        // Load episode likes
        if let dict = UserDefaults.standard.dictionary(forKey: episodeLikesKey) {
            episodeLikes = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                guard let episodeId = UUID(uuidString: key),
                      let userIds = value as? [String] else { return nil }
                let uuidArray = userIds.compactMap { UUID(uuidString: $0) }
                return (episodeId, uuidArray)
            })
        }
        
        // Load content views
        if let dict = UserDefaults.standard.dictionary(forKey: contentViewsKey) {
            contentViews = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                guard let contentId = UUID(uuidString: key),
                      let userIds = value as? [String] else { return nil }
                let uuidArray = userIds.compactMap { UUID(uuidString: $0) }
                return (contentId, uuidArray)
            })
        }
        
        // Load episode views
        if let dict = UserDefaults.standard.dictionary(forKey: episodeViewsKey) {
            episodeViews = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                guard let episodeId = UUID(uuidString: key),
                      let userIds = value as? [String] else { return nil }
                let uuidArray = userIds.compactMap { UUID(uuidString: $0) }
                return (episodeId, uuidArray)
            })
        }
    }
    
    func clearAllData() {
        contentLikes.removeAll()
        episodeLikes.removeAll()
        contentViews.removeAll()
        episodeViews.removeAll()
        UserDefaults.standard.removeObject(forKey: contentLikesKey)
        UserDefaults.standard.removeObject(forKey: episodeLikesKey)
        UserDefaults.standard.removeObject(forKey: contentViewsKey)
        UserDefaults.standard.removeObject(forKey: episodeViewsKey)
    }
}

