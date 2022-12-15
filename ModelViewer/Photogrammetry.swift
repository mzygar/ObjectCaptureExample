//
//  Photogrammetry.swift
//  ModelViewer
//
//  Created by Michal Zygar on 14/12/2022.
//

import Foundation
import os
import RealityKit
import AppKit

private let logger = Logger(subsystem: "com.mzygar.modelviewer",
                            category: "Model viewer")

class Photogrammetry: ObservableObject {
    var inputFolder: String? = nil
    var outputFilename: String? = "output.usdz"
    
    @Published
    var computedModelURL:URL?
    
    @Published
    var progress: Double = 0.0
    
    @Published
    var isRunning: Bool = false
    
    var outputFilenameURL:URL!
    
    func run(inputFolderPath:URL) {
        let inputFolderUrl = inputFolderPath
        outputFilenameURL = showSavePanel()
        let configuration = makeConfigurationFromArguments()
        logger.log("Using configuration: \(String(describing: configuration))")

        // Try to create the session, or else exit.
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: inputFolderUrl,
                                                     configuration: configuration)
            logger.log("Successfully created session.")
        } catch {
            logger.error("Error creating session: \(String(describing: error))")
            Foundation.exit(1)
        }
        guard let session = maybeSession else {
            Foundation.exit(1)
        }

        let waiter = Task {
            [weak self] in
            do {
                for try await output in session.outputs {
                    switch output {
                        case .processingComplete:
                            logger.log("Processing is complete!")

                        case .requestError(let request, let error):
                            logger.error("Request \(String(describing: request)) had an error: \(String(describing: error))")
                        case .requestComplete(let request, let result):
                        self?.handleRequestComplete(request: request, result: result)
                        case .requestProgress(let request, let fractionComplete):
                        self?.handleRequestProgress(request: request,
                                                                      fractionComplete: fractionComplete)
                        case .inputComplete:  // data ingestion only!
                            logger.log("Data ingestion is complete.  Beginning processing...")
                        case .invalidSample(let id, let reason):
                            logger.warning("Invalid Sample! id=\(id)  reason=\"\(reason)\"")
                        case .skippedSample(let id):
                            logger.warning("Sample id=\(id) was skipped by processing.")
                        case .automaticDownsampling:
                            logger.warning("Automatic downsampling was applied!")
                        case .processingCancelled:
                            logger.warning("Processing was cancelled.")
                        @unknown default:
                            logger.error("Output: unhandled message: \(output.localizedDescription)")

                    }
                }
            } catch {
                logger.error("Output: ERROR = \(String(describing: error))")
            }
    }

        isRunning = true
    // The compiler may deinitialize these objects since they may appear to be
        // unused. This keeps them from being deallocated until they exit.
        withExtendedLifetime((session, waiter)) {
            // Run the main process call on the request, then enter the main run
            // loop until you get the published completion event or error.
            do {
                let request = makeRequestFromArguments()
                logger.log("Using request: \(String(describing: request))")
                try session.process(requests: [ request ])
            } catch {
                logger.critical("Process got error: \(String(describing: error))")
    //            Foundation.exit(1)
            }
        }
    }

    
    func showSavePanel() -> URL? {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.usdz]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.title = "Save your model"
            savePanel.message = "Choose a folder and a name to store the image."
            savePanel.nameFieldLabel = "Image file name:"

            let response = savePanel.runModal()
            return response == .OK ? savePanel.url : nil
        }
    
    
/// Creates the session configuration by overriding any defaults with arguments specified.
    private func makeConfigurationFromArguments() -> PhotogrammetrySession.Configuration {
        var configuration = PhotogrammetrySession.Configuration()
        configuration.sampleOrdering = .unordered
        configuration.featureSensitivity = .normal
        return configuration
    }

    /// Creates a request to use based on the command-line arguments.
    private func makeRequestFromArguments() -> PhotogrammetrySession.Request {
        let outputUrl = URL(fileURLWithPath: outputFilename!)
        return PhotogrammetrySession.Request.modelFile(url: outputFilenameURL)
    }

    /// Called when the the session sends a request completed message.
    private func handleRequestComplete(request: PhotogrammetrySession.Request,
                                          result: PhotogrammetrySession.Result) {
        logger.log("Request complete: \(String(describing: request)) with result...")
        switch result {
        case .modelFile(let url):
            logger.log("\tmodelFile available at url=\(url)")
            DispatchQueue.main.async{
                self.computedModelURL = url
                self.isRunning = false
            }
        default:
            logger.warning("\tUnexpected result: \(String(describing: result))")
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    /// Called when the sessions sends a progress update message.
    private func handleRequestProgress(request: PhotogrammetrySession.Request,
                                          fractionComplete: Double) {
        logger.log("Progress(request = \(String(describing: request)) = \(fractionComplete)")
        DispatchQueue.main.async {
            self.progress = fractionComplete
        }
    }

}
//
//// MARK: - Helper Functions / Extensions
//
//private func handleRequestProgress(request: PhotogrammetrySession.Request,
//                           fractionComplete: Double) {
//print("Progress(request = \(String(describing: request)) = \(fractionComplete)")
//}

/// Error thrown when an illegal option is specified.
private enum IllegalOption: Swift.Error {
    case invalidDetail(String)
    case invalidSampleOverlap(String)
    case invalidSampleOrdering(String)
    case invalidFeatureSensitivity(String)
}

/// Extension to add a throwing initializer used as an option transform to verify the user-supplied arguments.
@available(macOS 12.0, *)
extension PhotogrammetrySession.Request.Detail {
    init(_ detail: String) throws {
        switch detail {
            case "preview": self = .preview
            case "reduced": self = .reduced
            case "medium": self = .medium
            case "full": self = .full
            case "raw": self = .raw
            default: throw IllegalOption.invalidDetail(detail)
        }
    }
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.SampleOrdering {
    init(sampleOrdering: String) throws {
        if sampleOrdering == "unordered" {
            self = .unordered
        } else if sampleOrdering == "sequential" {
            self = .sequential
        } else {
            throw IllegalOption.invalidSampleOrdering(sampleOrdering)
        }
    }
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    init(featureSensitivity: String) throws {
        if featureSensitivity == "normal" {
            self = .normal
        } else if featureSensitivity == "high" {
            self = .high
        } else {
            throw IllegalOption.invalidFeatureSensitivity(featureSensitivity)
        }
    }
}

