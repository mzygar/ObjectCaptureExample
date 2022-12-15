//
//  ContentView.swift
//  ModelViewer
//
//  Created by Michal Zygar on 14/12/2022.
//

import SwiftUI
import SceneKit
struct ContentView: View {
    @EnvironmentObject
    var converter: Photogrammetry
    
    @State
    var inputFolder: URL?
    @State
    var existingModel: URL?
    var title: String {
        if let photos = inputFolder?.lastPathComponent {
            return "Loaded photos from " + photos
        }
        
        if let model = converter.computedModelURL?.lastPathComponent {
            return "Loaded model named " + model
        }
        
        return "Load something to begin"
    }
    
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
            HStack {
                FolderSelector(inputFolder: $inputFolder,caption: "Choose image folder", canChooseDirectories: true)
                Button("Create model") {
                    converter.run(inputFolderPath: inputFolder!)
                }.disabled(inputFolder==nil)
                Spacer()
                FolderSelector(completion: { url in
                    converter.computedModelURL = url
                    inputFolder = nil
                }, inputFolder: $inputFolder, caption: "Load existing model", canChooseDirectories: false)
            }
            HStack {
                ProgressView(value: converter.progress)
                
                Text(converter.progress.formatted(.percent))
            }
            
            if let url = converter.computedModelURL {
                SceneView(scene: try! SCNScene(url:url),options: [.autoenablesDefaultLighting, .allowsCameraControl])
            } else {
                SceneView(scene: SCNScene(named: "kostka3d.usdz"),options: [.autoenablesDefaultLighting, .allowsCameraControl])
            
             }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
