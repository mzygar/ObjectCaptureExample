import SwiftUI

@main
struct ModelViewerApp: App {
    var converter = Photogrammetry()
    var body: some Scene {
        WindowGroup {
            ContentView(existingModel: converter.computedModelURL)
                .environmentObject(converter)   
        }
    }
}
