import SwiftUI

struct FavoritesLoopView: View {
    @EnvironmentObject var userState: UserState
    
    private var favoritesByService: [StreamingService: [Content]] {
        Dictionary(grouping: userState.myList, by: { $0.service })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                                    NavigationLink(destination: ContentDetailView(content: content)) {
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
                .padding(.vertical)
            }
            .navigationTitle("Favorites")
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
            )
        }
    }
} 