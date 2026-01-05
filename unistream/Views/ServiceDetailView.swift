import SwiftUI

struct ServiceDetailView: View {
    let service: StreamingService
    @StateObject private var mockData = MockData.shared
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    
    var serviceContent: [Content] {
        if service == .inTheaters {
            return mockData.nowPlaying
        } else {
            return mockData.content.filter { $0.service == service }
        }
    }
    
    var movies: [Content] {
        serviceContent.filter { !$0.isTVShow }
    }
    
    var tvShows: [Content] {
        serviceContent.filter { $0.isTVShow }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with service logo and name
                HStack(spacing: 16) {
                    if service == .inTheaters {
                        Image(systemName: "film.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(service.color)
                    } else if !service.logoURL.isEmpty {
                        AsyncImage(url: URL(string: service.logoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle()
                                .fill(service.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        .frame(width: 50, height: 50)
                    } else {
                        Circle()
                            .fill(service.color)
                            .frame(width: 50, height: 50)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(serviceContent.count) title\(serviceContent.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if mockData.isLoading {
                    ProgressView("Loading content...")
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if serviceContent.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No titles available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Check back later for new content")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    // Movies Section
                    if !movies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Movies")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(movies) { content in
                                        NavigationLink(destination: ContentDetailView(content: content)
                                            .environmentObject(userState)
                                            .environmentObject(interactionService)) {
                                            ContentCard(content: content)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // TV Shows Section
                    if !tvShows.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TV Shows")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(tvShows) { content in
                                        NavigationLink(destination: ContentDetailView(content: content)
                                            .environmentObject(userState)
                                            .environmentObject(interactionService)) {
                                            ContentCard(content: content)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // All Content Grid (if both movies and shows exist)
                    if !movies.isEmpty && !tvShows.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Content")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(serviceContent) { content in
                                    NavigationLink(destination: ContentDetailView(content: content)
                                        .environmentObject(userState)
                                        .environmentObject(interactionService)) {
                                        ContentCard(content: content)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if mockData.content.isEmpty {
                await mockData.loadContent()
            }
        }
    }
}

