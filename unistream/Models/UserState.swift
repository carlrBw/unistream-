import SwiftUI
import Foundation

@MainActor
class UserState: ObservableObject {
    @Published var myList: [Content] = []
    @Published var loopedEpisodes: [(content: Content, episode: Episode)] = []
    @Published var loopedSeries: [Content] = []
    @Published var watchedEpisodes: [UUID] = [] // Track watched episode IDs
    @Published var watchedMovies: [UUID] = [] // Track watched movie IDs
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let persistence = PersistenceService.shared
    private var isLoading = false
    
    init() {
        isLoading = true
        loadSavedData()
        loadWatchedEpisodes()
        loadWatchedMovies()
        isLoading = false
    }
    
    private func loadSavedData() {
        // Load authentication state
        isAuthenticated = persistence.loadAuthenticationState()
        
        // Load user data
        if let savedUser = persistence.loadUser() {
            currentUser = savedUser
        }
        
        // Load favorites/my list
        myList = persistence.loadMyList()
    }
    
    private func saveMyList() {
        guard !isLoading else { return }
        persistence.saveMyList(myList)
    }
    
    // Add a method to add a comment to a user's profile
    func addComment(_ comment: Comment) {
        guard let user = currentUser else { return }
        user.comments.append(comment)
        currentUser = user
        PersistenceService.shared.saveUser(user)
    }
    
    // Add a method to get all comments made by the user
    func getUserComments() -> [Comment] {
        return currentUser?.comments ?? []
    }
    
    func addToMyList(_ content: Content) {
        if !myList.contains(where: { $0.id == content.id }) {
            myList.append(content)
            saveMyList()
        }
    }
    
    func removeFromMyList(_ content: Content) {
        myList.removeAll(where: { $0.id == content.id })
        saveMyList()
    }
    
    func isInMyList(_ content: Content) -> Bool {
        return myList.contains(where: { $0.id == content.id })
    }
    
    func addToLoopedEpisodes(content: Content, episode: Episode) {
        if !loopedEpisodes.contains(where: { $0.episode.id == episode.id }) {
            loopedEpisodes.append((content: content, episode: episode))
        }
    }
    
    func addToLoopedSeries(_ content: Content) {
        if !loopedSeries.contains(where: { $0.id == content.id }) {
            loopedSeries.append(content)
        }
    }
    
    func markEpisodeAsWatched(_ episode: Episode) {
        if !watchedEpisodes.contains(episode.id) {
            watchedEpisodes.append(episode.id)
            saveWatchedEpisodes()
        }
    }
    
    func markEpisodeAsUnwatched(_ episode: Episode) {
        watchedEpisodes.removeAll(where: { $0 == episode.id })
        saveWatchedEpisodes()
    }
    
    func isEpisodeWatched(_ episode: Episode) -> Bool {
        return watchedEpisodes.contains(episode.id)
    }
    
    private func saveWatchedEpisodes() {
        guard !isLoading else { return }
        // Save watched episodes to UserDefaults
        UserDefaults.standard.set(watchedEpisodes.map { $0.uuidString }, forKey: "watchedEpisodes")
    }
    
    private func loadWatchedEpisodes() {
        if let episodeIds = UserDefaults.standard.array(forKey: "watchedEpisodes") as? [String] {
            watchedEpisodes = episodeIds.compactMap { UUID(uuidString: $0) }
        }
    }
    
    func markMovieAsWatched(_ content: Content) {
        if !watchedMovies.contains(content.id) {
            watchedMovies.append(content.id)
            saveWatchedMovies()
        }
    }
    
    func markMovieAsUnwatched(_ content: Content) {
        watchedMovies.removeAll(where: { $0 == content.id })
        saveWatchedMovies()
    }
    
    func isMovieWatched(_ content: Content) -> Bool {
        return watchedMovies.contains(content.id)
    }
    
    private func saveWatchedMovies() {
        guard !isLoading else { return }
        // Save watched movies to UserDefaults
        UserDefaults.standard.set(watchedMovies.map { $0.uuidString }, forKey: "watchedMovies")
    }
    
    private func loadWatchedMovies() {
        if let movieIds = UserDefaults.standard.array(forKey: "watchedMovies") as? [String] {
            watchedMovies = movieIds.compactMap { UUID(uuidString: $0) }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        // Simulate network request
        try await Task.sleep(for: .seconds(1))
        
        // For demo purposes, accept any valid-looking email/password
        guard email.contains("@"), password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        // Create a sample user for successful login
        let user = User(
            username: email.split(separator: "@").first?.description ?? "user",
            joinDate: Date(),
            addedContent: [],
            watchHistory: [],
            activeSubscriptions: SubscriptionData.subscriptions,
            comments: []
        )
        
        self.currentUser = user
        self.isAuthenticated = true
        PersistenceService.shared.saveUser(user)
        PersistenceService.shared.saveAuthenticationState(true)
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        myList = []
        loopedEpisodes = []
        loopedSeries = []
        watchedEpisodes = []
        watchedMovies = []
        persistence.clearAllData()
        UserDefaults.standard.removeObject(forKey: "watchedEpisodes")
        UserDefaults.standard.removeObject(forKey: "watchedMovies")
    }
    
    func signUp(username: String, email: String, password: String) async throws {
        // Simulate network request
        try await Task.sleep(for: .seconds(1))
        
        // Validate email format
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        // Validate password length
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        let newUser = User(
            username: username,
            joinDate: Date(),
            addedContent: [],
            watchHistory: [],
            activeSubscriptions: [],
            comments: []
        )
        
        self.currentUser = newUser
        self.isAuthenticated = true
        PersistenceService.shared.saveUser(newUser)
        PersistenceService.shared.saveAuthenticationState(true)
    }
}

// Add authentication errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case weakPassword
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .networkError:
            return "Network error. Please try again"
        }
    }
} 
