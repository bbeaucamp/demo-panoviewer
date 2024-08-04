import SwiftUI

class ImageViewModel: ObservableObject {
    @Published var image: NSImage?
    
    func loadImage(from url: URL) {
        print("Attempting to load image from URL: \(url.path)")
        do {
            let data = try Data(contentsOf: url)
            loadImage(data: data)
        } catch {
            print("Error loading data from URL: \(error.localizedDescription)")
        }
    }
    
    func loadImage(data: Data) {
        print("Attempting to load image from data, size: \(data.count) bytes")
        if let newImage = NSImage(data: data) {
            DispatchQueue.main.async {
                self.image = newImage
                print("Image loaded successfully")
            }
        } else {
            print("Failed to create NSImage from provided data")
            let dataPreview = data.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ")
            print("First 16 bytes of data: \(dataPreview)")
            
            // Try to determine the file type based on the data
            if data.starts(with: [0xFF, 0xD8]) {
                print("Data appears to be a JPEG")
            } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                print("Data appears to be a PNG")
            } else {
                print("Unable to determine image type from data")
            }
        }
    }
}
