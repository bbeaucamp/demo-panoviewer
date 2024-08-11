import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ImageViewModel
    @State private var yaw: Float = 0
    @State private var pitch: Float = 0
    @State private var roll: Float = 0
    @State private var fov: Float = 90

    var body: some View {
        VStack {
            if viewModel.image != nil {
                EquirectangularViewer(viewModel: viewModel, yaw: $yaw, pitch: $pitch, roll: $roll, fov: $fov)
            } else {
                Text("No image loaded")
            }
            
            HStack {
                VStack {
                    Slider(value: $yaw, in: -Float.pi...Float.pi) {
                        Text("Yaw")
                    }
                    Slider(value: $pitch, in: -Float.pi/2...Float.pi/2) {
                        Text("Pitch")
                    }
                    Slider(value: $roll, in: -Float.pi...Float.pi) {
                        Text("Roll")
                    }
                    Slider(value: $fov, in: 30...120) {
                        Text("FOV")
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 300, minHeight: 300)
        .onDrop(of: [.image], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadDataRepresentation(for: .image) { data, error in
                if error == nil, let data = data {
                    DispatchQueue.main.async {
                        self.viewModel.loadImage(data: data)
                    }
                }
            }
            return true
        }
    }
}
