import SwiftUI
import UIKit

class ImageColorExtractor: ObservableObject {
    @Published var dominantColors: [Color] = [.blue.opacity(0.8), .black]
    
    func extractColors(from urlString: String) {
        guard let url = URL(string: urlString) else {
            dominantColors = [.blue.opacity(0.8), .black]
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        dominantColors = [.blue.opacity(0.8), .black]
                    }
                    return
                }
                
                await MainActor.run {
                    dominantColors = extractDominantColors(from: image)
                }
            } catch {
                await MainActor.run {
                    dominantColors = [.blue.opacity(0.8), .black]
                }
            }
        }
    }
    
    private func extractDominantColors(from image: UIImage) -> [Color] {
        guard let cgImage = image.cgImage else {
            return [.blue.opacity(0.8), .black]
        }
        
        // Resize image for faster processing
        let size = CGSize(width: 100, height: 100)
        let resizedImage = resizeImage(image, to: size)
        
        guard let resizedCGImage = resizedImage.cgImage else {
            return [.blue.opacity(0.8), .black]
        }
        
        // Get pixel data
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return [.blue.opacity(0.8), .black]
        }
        
        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Sample colors from different regions
        var colors: [UIColor] = []
        
        // Top-left corner
        if let topLeftColor = getColorAt(pixelData: pixelData, x: width / 4, y: height / 4, width: width) {
            colors.append(topLeftColor)
        }
        
        // Top-right corner
        if let topRightColor = getColorAt(pixelData: pixelData, x: 3 * width / 4, y: height / 4, width: width) {
            colors.append(topRightColor)
        }
        
        // Center
        if let centerColor = getColorAt(pixelData: pixelData, x: width / 2, y: height / 2, width: width) {
            colors.append(centerColor)
        }
        
        // Bottom
        if let bottomColor = getColorAt(pixelData: pixelData, x: width / 2, y: 3 * height / 4, width: width) {
            colors.append(bottomColor)
        }
        
        // Convert to SwiftUI Colors and create gradient
        let swiftUIColors = colors.map { Color($0) }
        
        if swiftUIColors.isEmpty {
            return [.blue.opacity(0.8), .black]
        }
        
        // Create a gradient from the extracted colors to black
        let primaryColor = swiftUIColors.first ?? .blue.opacity(0.8)
        let secondaryColor = swiftUIColors.count > 1 ? swiftUIColors[1] : primaryColor.opacity(0.6)
        
        return [
            primaryColor.opacity(0.9),
            secondaryColor.opacity(0.7),
            .black.opacity(0.95)
        ]
    }
    
    private func getColorAt(pixelData: [UInt8], x: Int, y: Int, width: Int) -> UIColor? {
        let index = (y * width + x) * 4
        guard index + 3 < pixelData.count else { return nil }
        
        let r = CGFloat(pixelData[index]) / 255.0
        let g = CGFloat(pixelData[index + 1]) / 255.0
        let b = CGFloat(pixelData[index + 2]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
    }
}

