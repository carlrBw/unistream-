import SwiftUI
import AVKit
import WebKit

struct TrailerCarousel: View {
    let bannerURL: String
    let trailerKey: String?
    @State private var showTrailer = false
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            if showTrailer && trailerKey != nil {
                // Show YouTube trailer
                YouTubePlayerView(videoKey: trailerKey!)
                    .frame(height: 400)
                    .clipped()
            } else {
                // Show banner image
                AsyncImage(url: URL(string: bannerURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                        .frame(height: 400)
                }
            }
        }
        .onAppear {
            // Start timer to show trailer after 5 seconds
            if trailerKey != nil {
                timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showTrailer = true
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

// YouTube Player using WebView
struct YouTubePlayerView: UIViewRepresentable {
    let videoKey: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create YouTube embed URL
        let embedURL = "https://www.youtube.com/embed/\(videoKey)?autoplay=1&playsinline=1&controls=1&modestbranding=1&rel=0"
        
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Video loaded
        }
    }
}

