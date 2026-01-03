import SwiftUI

struct Theme: Identifiable {
    let id = UUID()
    let name: String
    let primary: Color
    let secondary: Color
    let background: LinearGradient
    
    static let themes: [Theme] = [
        Theme(
            name: "Ocean Blue",
            primary: .blue,
            secondary: .cyan,
            background: LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        Theme(
            name: "Sunset",
            primary: .orange,
            secondary: .pink,
            background: LinearGradient(
                gradient: Gradient(colors: [.orange.opacity(0.8), .pink.opacity(0.4), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        Theme(
            name: "Forest",
            primary: .green,
            secondary: .mint,
            background: LinearGradient(
                gradient: Gradient(colors: [.green.opacity(0.8), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        Theme(
            name: "Purple Rain",
            primary: .purple,
            secondary: .indigo,
            background: LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.8), .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    ]
} 