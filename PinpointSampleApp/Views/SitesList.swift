import SwiftUI
import AlertToast
import Pinpoint_Easylocate_iOS_SDK

struct SitesList: View {
    @ObservedObject var sfm = SiteFileManager.shared
    @ObservedObject var alerts = AlertController.shared
    let logger = Logging.shared
    
    @State private var list = [String]()
    @State private var selectedItem: String? = nil
    @State private var showImporter = false
    @State private var showWebDavImporter = false
    @State private var showLoading = false
    @State private var showSiteFileImportAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            headerButtons
            Text("Imported Maps")
                .font(.headline)
            if showLoading {
                ProgressView()
            }
            if list.isEmpty {
                emptyListView
            } else {
                siteFilesListView
            }
        }
        .presentationDragIndicator(.visible)
        .task { list = sfm.getSitefilesList() }
        .toast(isPresenting: $showSiteFileImportAlert) {
            AlertToast(type: .error(.red), title: "Wrong Sitefile format!")
        }
        .sheet(isPresented: $showWebDavImporter, onDismiss: { list = sfm.getSitefilesList() }) {
            RemoteSitesList()
        }
        .navigationTitle("Import SiteFile")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip], allowsMultipleSelection: false, onCompletion: handleFileImport)
    }
    
    private var headerButtons: some View {
        HStack {
            importButton(imageName: "folder", text: "Local", action: { showImporter = true })
            importButton(imageName: "server.rack", text: "Cloud", action: { showWebDavImporter.toggle() })
            Spacer()
            Button(action: clearCache) {
                Text("Delete all")
                    .foregroundColor(.red)
            }
            .disabled(list.isEmpty)
            .padding()
        }
        .padding()
    }
    
    private var emptyListView: some View {
        VStack {
            Spacer().frame(height: 100)
            Image(systemName: "square.3.layers.3d.slash")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
            Text("No Maps imported")
                .font(.headline)
                .padding()
            Spacer()
        }
    }
    
    private var siteFilesListView: some View {
        List(list, id: \.self, selection: $selectedItem) { item in
            Button {
                handleSiteFileSelection(item: item)
            } label: {
                Text(item)
                    .foregroundColor(sfm.siteFile.map.mapFile != item ? .black : CustomColor.pinpoint_orange)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
    
    private func importButton(imageName: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                Text(text)
            }
        }
        .padding(.trailing)
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            guard selectedFile.startAccessingSecurityScopedResource() else { return }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(selectedFile.lastPathComponent)
            try FileManager.default.copyItem(at: selectedFile, to: destinationUrl)
            
            Task {
                do {
                    try await sfm.unarchiveFile(sourceFile: destinationUrl)
                    list = sfm.getSitefilesList()
                    try sfm.loadSiteFile(siteFileName: selectedFile.lastPathComponent)
                } catch {
                    showSiteFileImportAlert.toggle()
                }
            }
        } catch {
            showSiteFileImportAlert.toggle()
        }
    }
    
    private func handleSiteFileSelection(item: String) {
        logger.log(type: .info, "Selected site \(item)")
        selectedItem = item
        if let newItem = selectedItem {
            do {
                try sfm.loadSiteFile(siteFileName: newItem)
                dismiss()
            } catch {
                showSiteFileImportAlert.toggle()
            }
        }
    }
    
    func clearCache(){
        let fileManager = FileManager.default
        do {
            let documentDirectoryURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in fileURLs {
                try fileManager.removeItem(at: url)
                list.removeAll()
            }
            sfm.siteFile = SiteData()
            sfm.floorImage = UIImage()
        } catch {
            print(error)
        }
    }
}


struct LocalSiteFileList_Previews: PreviewProvider {
    static var previews: some View {
        SitesList()
    }
}
