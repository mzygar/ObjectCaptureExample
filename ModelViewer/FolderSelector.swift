import SwiftUI

struct FolderSelector: View {
    
    @Binding
    var inputFolder:URL?
    
    var caption: String
    var canChooseDirectories: Bool
    
    var completion:((URL?)->(Void))?
    
    var body: some View {
        Button(caption) {
            self.selectFolder()
        }
    }
    
    func selectFolder() {
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        folderPicker.canChooseDirectories = canChooseDirectories
        folderPicker.canChooseFiles = !canChooseDirectories
        folderPicker.allowsMultipleSelection = false
        folderPicker.canDownloadUbiquitousContents = true
        folderPicker.canResolveUbiquitousConflicts = true
        
        folderPicker.begin { response in
            
            if response == .OK {
                let pickedFolders = folderPicker.urls
                print (pickedFolders)
                inputFolder = pickedFolders.first!
                completion?(inputFolder)
            }
        }
    }
}
