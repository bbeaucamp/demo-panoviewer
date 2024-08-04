import SwiftUI

class ImageViewModel: ObservableObject {
    @Published var image: NSImage?
    
    func loadImage(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            loadImage(data: data)
        } catch {
            print("Error loading data from URL: \(error.localizedDescription)")
        }
    }
    
    func loadImage(data: Data) {
        if let newImage = NSImage(data: data) {
            DispatchQueue.main.async {
                self.image = newImage
            }
        }
    }
}
