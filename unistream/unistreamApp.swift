//
//  unistreamApp.swift
//  unistream
//
//  Created by Carl Baker-Williams on 2/26/25.
//

import SwiftUI
import UIKit
import AuthenticationServices

@main
struct unistreamApp: App {
    @StateObject private var userState = UserState()
    @StateObject private var interactionService = UserInteractionService.shared
    
    var body: some Scene {                                                                                                   
        WindowGroup {
                MainTabView()
                    .environmentObject(userState)
                    .environmentObject(interactionService)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var userState: UserState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            if userState.isAuthenticated {
                UserProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(1)
            } else {
                UnauthenticatedProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(1)
            }
            
            FavoritesLoopView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
                .tag(2)
            
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .preferredColorScheme(.dark)
    }
}

// Update SettingsTabView to handle authentication
struct SettingsTabView: View {
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        NavigationStack {
            SettingsView(user: userState.currentUser)
                .navigationTitle("Settings")
        }
    }
}

// Profile view for unauthenticated users with inline login
struct UnauthenticatedProfileView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var username = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo/Title
                        VStack(spacing: 10) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.white)
                            
                            Text("Unistream")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 50)
                        
                        // Login/Sign Up Form
                        VStack(spacing: 20) {
                            // Toggle between Login and Sign Up
                            Picker("Mode", selection: $isSignUpMode) {
                                Text("Sign In").tag(false)
                                Text("Sign Up").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Username field (only for sign up)
                            if isSignUpMode {
                                TextField("Choose a username", text: $username)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .tint(.blue)
                                    .padding(.horizontal)
                            }
                            
                            // Email/Username field
                            TextField("Enter your email or username", text: $email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .tint(.blue)
                                .padding(.horizontal)
                            
                            // Password field
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .tint(.blue)
                                .padding(.horizontal)
                            
                            // Confirm Password field (only for sign up)
                            if isSignUpMode {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .tint(.blue)
                                    .padding(.horizontal)
                            }
                            
                            // Submit button
                            Button(action: handleSubmit) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.primary)
                                } else {
                                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .disabled(isLoading)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))
                            Text("or")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.horizontal)
                        
                        // Circular Social Icons
                        HStack(spacing: 30) {
                            // Apple
                            Button(action: handleAppleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.black)
                                        .font(.title2)
                                }
                            }
                            .disabled(isLoading)
                            
                            // Google
                            Button(action: signInWithGoogle) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                    
                                    if let googleImage = UIImage(named: "google_logo") {
                                        Image(uiImage: googleImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Image(systemName: "globe")
                                            .foregroundColor(.black)
                                            .font(.title2)
                                    }
                                }
                            }
                            .disabled(isLoading)
                            
                            // Facebook
                            Button(action: signInWithFacebook) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.26, green: 0.40, blue: 0.70))
                                        .frame(width: 60, height: 60)
                                    
                                    if let fbImage = UIImage(named: "facebook_logo") {
                                        Image(uiImage: fbImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Image(systemName: "f.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    }
                                }
                            }
                            .disabled(isLoading)
                            
                            // X (Twitter)
                            Button(action: signInWithX) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 60, height: 60)
                                    
                                    if let xImage = UIImage(named: "x_logo") {
                                        Image(uiImage: xImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Text("X")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .disabled(isLoading)
                        }
                        .padding(.vertical, 20)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSubmit() {
        isLoading = true
        
        if isSignUpMode {
            // Sign Up validation
            guard !username.isEmpty else {
                showError("Please enter a username")
                return
            }
            
            guard !email.isEmpty, email.contains("@") else {
                showError("Please enter a valid email")
                return
            }
            
            guard password.count >= 6 else {
                showError("Password must be at least 6 characters")
                return
            }
            
            guard password == confirmPassword else {
                showError("Passwords don't match")
                return
            }
            
            Task {
                do {
                    try await userState.signUp(username: username, email: email, password: password)
                    await MainActor.run {
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        showError(error.localizedDescription)
                    }
                }
            }
        } else {
            // Sign In validation
            guard !email.isEmpty else {
                showError("Please enter your email or username")
                return
            }
            
            guard !password.isEmpty else {
                showError("Please enter your password")
                return
            }
            
            Task {
                do {
                    try await userState.signIn(email: email, password: password)
                    await MainActor.run {
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        showError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func handleAppleSignIn() {
        isLoading = true
        // Apple Sign In will be handled via SignInWithAppleButton if needed
        // For now, this is a placeholder
        isLoading = false
    }
    
    private func signInWithGoogle() {
        isLoading = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showError("Unable to present login")
            return
        }
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithGoogle(presenting: rootViewController)
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func signInWithFacebook() {
        isLoading = true
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithFacebook()
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func signInWithX() {
        isLoading = true
        
        Task {
            do {
                let user = try await SocialAuthService.shared.signInWithX()
                await MainActor.run {
                    userState.currentUser = user
                    userState.isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        isLoading = false
        alertMessage = message
        showingAlert = true
    }
}


#Preview {
    MainTabView()
        .environmentObject(UserState())
        .environmentObject(UserInteractionService.shared)
}
