import SwiftUI

@main
struct SimpleImageViewerApp: App {
    @StateObject private var viewModel = ImageViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView(viewModel: ImageViewModel())
}
