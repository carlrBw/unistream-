import Foundation

class PersistenceService {
    static let shared = PersistenceService()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let isAuthenticated = "isAuthenticated"
        static let currentUser = "currentUser"
        static let myList = "myList"
        static let favorites = "favorites"
        static let userComments = "userComments"
    }
    
    // MARK: - Authentication
    func saveAuthenticationState(_ isAuthenticated: Bool) {
        userDefaults.set(isAuthenticated, forKey: Keys.isAuthenticated)
    }
    
    func loadAuthenticationState() -> Bool {
        return userDefaults.bool(forKey: Keys.isAuthenticated)
    }
    
    // MARK: - User Data
    @MainActor func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user.toCodable()) {
            userDefaults.set(encoded, forKey: Keys.currentUser)
        }
    }
    
    @MainActor func loadUser() -> User? {
        guard let data = userDefaults.data(forKey: Keys.currentUser),
              let codableUser = try? JSONDecoder().decode(CodableUser.self, from: data) else {
            return nil
        }
        return User(from: codableUser)
    }
    
    // MARK: - Favorites/My List
    func saveMyList(_ contentList: [Content]) {
        let codableContent = contentList.map { $0.toCodable() }
        if let encoded = try? JSONEncoder().encode(codableContent) {
            userDefaults.set(encoded, forKey: Keys.myList)
        }
    }
    
    func loadMyList() -> [Content] {
        guard let data = userDefaults.data(forKey: Keys.myList),
              let codableContent = try? JSONDecoder().decode([CodableContent].self, from: data) else {
            return []
        }
        return codableContent.map { Content(from: $0) }
    }
    
    // MARK: - Comments
    func saveComments(_ comments: [Comment]) {
        let codableComments = comments.map { $0.toCodable() }
        if let encoded = try? JSONEncoder().encode(codableComments) {
            userDefaults.set(encoded, forKey: Keys.userComments)
        }
    }
    
    func loadComments() -> [Comment] {
        guard let data = userDefaults.data(forKey: Keys.userComments),
              let codableComments = try? JSONDecoder().decode([CodableComment].self, from: data) else {
            return []
        }
        // Note: Comments will be reconstructed when user data is loaded
        return codableComments.compactMap { Comment(from: $0) }
    }
    
    // MARK: - Clear All Data
    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.isAuthenticated)
        userDefaults.removeObject(forKey: Keys.currentUser)
        userDefaults.removeObject(forKey: Keys.myList)
        userDefaults.removeObject(forKey: Keys.favorites)
        userDefaults.removeObject(forKey: Keys.userComments)
    }
}

