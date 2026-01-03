//
//  unistreamApp.swift
//  unistream
//
//  Created by Carl Baker-Williams on 2/26/25.
//

import SwiftUI

@main
struct unistreamApp: App {
    @StateObject private var userState = UserState()
    
    var body: some Scene {                                                                                                   
        WindowGroup {
            MainTabView()
                .environmentObject(userState)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            if userState.isAuthenticated {
                UserProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            } else {
                UnauthenticatedProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            
            FavoritesLoopView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
            
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
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

// A simple profile tab for unauthenticated users showing Login and Sign Up options
struct UnauthenticatedProfileView: View {
    @EnvironmentObject var userState: UserState
    @State private var showingLoginView = false
    @State private var showingSignUpView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Text("Sign in to view your profile")
                    .foregroundColor(.gray)
                
                Button("Log In") {
                    showingLoginView = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("Sign Up") {
                    showingSignUpView = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .sheet(isPresented: $showingLoginView) {
                LoginView()
                    .environmentObject(userState)
            }
            .sheet(isPresented: $showingSignUpView) {
                SignUpView()
                    .environmentObject(userState)
            }
        }
    }
}


#Preview {
    MainTabView()
        .environmentObject(UserState())
}
