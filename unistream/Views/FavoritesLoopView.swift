import SwiftUI

struct FavoritesLoopView: View {
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    @Binding var selectedTab: Int
    
    private var favoritesByService: [StreamingService: [Content]] {
        Dictionary(grouping: userState.myList, by: { $0.service })
    }
    
    var body: some View {
        NavigationStack {
            if userState.isAuthenticated {
            ScrollView {
                    VStack(spacing: 24) {
                        if userState.myList.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No favorites yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Add titles to your favorites to see them here")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        } else {
                            ForEach(StreamingService.allCases.filter { favoritesByService[$0]?.isEmpty == false }, id: \.self) { service in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Section Header by Network
                                    HStack(spacing: 10) {
                                        AsyncImage(url: URL(string: service.logoURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            Text(service.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(height: 18)
                                        
                                        Text(service.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)
                                    
                                    VStack(spacing: 16) {
                                        ForEach(favoritesByService[service] ?? []) { content in
                                            NavigationLink(destination: ContentDetailView(content: content)
                                                .environmentObject(userState)
                                                .environmentObject(interactionService)) {
                            HStack(spacing: 15) {
                                // Thumbnail
                                AsyncImage(url: URL(string: content.thumbnailURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(content.service.color.opacity(0.3))
                                        .overlay(
                                            ProgressView()
                                                .tint(.white)
                                        )
                                }
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(content.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(content.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        AsyncImage(url: URL(string: content.service.logoURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            Text(content.service.rawValue)
                                        }
                                        .frame(height: 15)
                                        .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                                            Image(systemName: "heart.fill")
                                                                .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(15)
                        }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        EmptyView()
                    }
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red.opacity(0.7))
                    
                    Text("Sign in to view your favorites")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Log in to save and access your favorite titles")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            // Switch to Profile tab (index 1) for login
                            selectedTab = 1
                        }) {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            // Switch to Profile tab (index 1) for sign up
                            selectedTab = 1
                        }) {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
            }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        EmptyView()
                    }
                }
            }
        }
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
            )
    }
} 