import SwiftUI
import Foundation

@MainActor
class UserState: ObservableObject {
    @Published var myList: [Content] = []
    @Published var loopedEpisodes: [(content: Content, episode: Episode)] = []
    @Published var loopedSeries: [Content] = []
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let persistence = PersistenceService.shared
    private var isLoading = false
    
    init() {
        isLoading = true
        loadSavedData()
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
        persistence.clearAllData()
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
