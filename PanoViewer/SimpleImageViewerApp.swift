import SwiftUI

@main
struct SimpleImageViewerApp: App {
    @StateObject private var viewModel = ImageViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("O")
            }
        }
    }
    
    func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                viewModel.loadImage(from: url)
            }
        }
    }
}
