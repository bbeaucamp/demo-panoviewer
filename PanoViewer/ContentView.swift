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
        .onDrop(of: [.image], isTargeted: nil) { providers, _ in
            guard let provider = providers.first else { return false }
            _ = provider.loadDataRepresentation(for: .image) { data, error in
                if error == nil, let data {
                    DispatchQueue.main.async {
                        self.viewModel.loadImage(data: data)
                    }
                }
            }
                
            return true
        }
    }
}
