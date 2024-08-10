import SwiftUI
import UniformTypeIdentifiers
import SceneKit

struct ContentView: View {
    @ObservedObject var viewModel: ImageViewModel
    
    var body: some View {
        ZStack {
            SceneView(
                scene: viewModel.scene,
                pointOfView: viewModel.cameraNode
//                options: [.allowsCameraControl]
            )
            .gesture(DragGesture().onChanged(viewModel.handlePan))
            .gesture(MagnificationGesture().onChanged(viewModel.handlePinch))
            
            VStack {
                Slider(value: $viewModel.yaw, in: -Float.pi...Float.pi, step: 0.01) { Text("Yaw") }
                Slider(value: $viewModel.pitch, in: -Float.pi/2...Float.pi/2, step: 0.01) { Text("Pitch") }
                Slider(value: $viewModel.roll, in: -Float.pi...Float.pi, step: 0.01) { Text("Roll") }
                Slider(value: $viewModel.fov, in: 30...120, step: 1) { Text("FOV") }
            }
            .padding()
        }
    }
}
