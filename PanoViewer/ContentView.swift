import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ImageViewModel
    
    var body: some View {
        VStack {
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("No image loaded")
            }
        }
        .frame(minWidth: 300, minHeight: 300)
        .onDrop(of: [UTType.image, UTType.fileURL], isTargeted: nil) { providers, _ in
            print("Drag detected")
            print("Number of providers: \(providers.count)")
            
            for (index, provider) in providers.enumerated() {
                print("Processing provider \(index + 1)")
                print("Supported identifiers: \(provider.registeredTypeIdentifiers)")
                
                for identifier in provider.registeredTypeIdentifiers {
                    provider.loadItem(forTypeIdentifier: identifier, options: nil) { item, error in
                        if let error = error {
                            print("Error loading item for identifier \(identifier): \(error.localizedDescription)")
                        } else if let data = item as? Data {
                            print("Data loaded for identifier \(identifier), size: \(data.count) bytes")
                            DispatchQueue.main.async {
                                self.viewModel.loadImage(data: data)
                            }
                            return
                        } else if let url = item as? URL {
                            print("URL loaded for identifier \(identifier): \(url.path)")
                            DispatchQueue.main.async {
                                self.viewModel.loadImage(from: url)
                            }
                            return
                        } else {
                            print("Unknown item type for identifier \(identifier)")
                        }
                    }
                }
            }
            
            return true
        }
    }
}
