import SwiftUI
import UIKit

@MainActor
class SocialAuthService {
    static let shared = SocialAuthService()
    
    // Mock Google Sign In
    func signInWithGoogle(presenting: UIViewController) async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // Simulate successful Google sign in
        return User(
            username: "Google User",
            joinDate: Date(),
            addedContent: [],
            watchHistory: [],
            activeSubscriptions: [],
            comments: []
        )
    }
    
    // Mock Facebook Sign In
    func signInWithFacebook() async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // Simulate successful Facebook sign in
        return User(
            username: "Facebook User",
            joinDate: Date(),
            addedContent: [],
            watchHistory: [],
            activeSubscriptions: [],
            comments: []
        )
    }
    
    // Mock X (Twitter) Sign In
    func signInWithX() async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // For demo purposes, simulate a successful sign in
        return User(
            username: "X User",
            joinDate: Date(),
            addedContent: [],
            watchHistory: [],
            activeSubscriptions: [],
            comments: []
        )
    }
}

// Add to AuthError enum if not already defined
extension AuthError {
    static let configError = AuthError.custom("Configuration error")
    static let permissionDenied = AuthError.custom("Permission denied")
    static let cancelled = AuthError.custom("Sign in cancelled")
    static let notImplemented = AuthError.custom("Not implemented yet")
    
    static func custom(_ message: String) -> AuthError {
        return .networkError // Use existing case but with custom message
    }
}

// Add UIViewController typealias for iOS
#if canImport(UIKit)
import UIKit
#else
import AppKit
typealias UIViewController = NSViewController
#endif 