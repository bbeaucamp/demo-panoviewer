import SwiftUI
import MetalKit

class ImageViewModel: ObservableObject {
    @Published var image: NSImage?
    @Published var texture: MTLTexture?
    
    private let device: MTLDevice?
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()
    }
    
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
                self.createTexture(from: newImage)
            }
        } else {
            print("Failed to create NSImage from data")
        }
    }
    
    private func createTexture(from image: NSImage) {
        guard let device = self.device,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage from NSImage")
            return
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            print("Failed to create texture")
            return
        }
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let region = MTLRegionMake2D(0, 0, width, height)
        
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        if let data = context.data {
            texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: bytesPerRow)
            
            DispatchQueue.main.async {
                self.texture = texture
                print("Texture created successfully")  // Debug print
            }
        } else {
            print("Failed to get context data")
        }
    }
}
