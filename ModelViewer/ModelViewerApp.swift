//
//  ModelViewerApp.swift
//  ModelViewer
//
//  Created by Michal Zygar on 14/12/2022.
//

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