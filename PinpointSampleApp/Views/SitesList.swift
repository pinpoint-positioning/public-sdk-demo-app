import SwiftUI
import AlertToast
import Pinpoint_Easylocate_iOS_SDK
import WebDAV

struct SitesList: View {
    @ObservedObject var sfm = SiteFileManager.shared
    @ObservedObject var alerts = AlertController.shared
    let logger = Logging.shared

    @State var list: [SiteFile] = []
    @State private var showImporter = false
    @State private var showWebDavImporter = false
    @State private var showLoading = true
    @State private var showSiteFileImportAlert = false
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("selectedSiteLocalName") private var selectedSiteLocalName: String?

    var selectedItem: SiteFile? {
        if let localName = selectedSiteLocalName {
            return list.first(where: { $0.localName == localName })
        }
        return nil
    }

    var body: some View {
        VStack {
            headerButtons
            Text("Imported Maps")
                .font(.headline)
            
            if showLoading {
                ProgressView()
                    .onAppear(perform: loadSiteFiles)
            }
            
            if list.isEmpty && !showLoading {
                emptyListView
            } else {
                siteFilesListView
            }
        }
        .presentationDragIndicator(.visible)
        .toast(isPresenting: $showSiteFileImportAlert) {
            AlertToast(type: .error(.red), title: "Wrong Sitefile format!")
        }
        .sheet(isPresented: $showWebDavImporter, onDismiss: { loadSiteFiles() }) {
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
        List(Array(list.enumerated()), id: \.offset) { index, site in
            Button {
                handleSiteFileSelection(item: site)
            } label: {
                HStack {
                    Image(uiImage: site.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                    
                    VStack(alignment: .leading) {
                        Text(site.siteData.map.mapName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(site.localName)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("SiteID: \(site.siteData.map.mapSiteId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("UWB-Channel: \(String(site.siteData.map.uwbChannel))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    if site.localName == selectedSiteLocalName {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .scrollContentBackground(.hidden)
        .listStyle(InsetGroupedListStyle())
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
    
    private func loadSiteFiles() {
        showLoading = true
            let fetchedList = sfm.getSitefilesList()
            
            DispatchQueue.main.async {
                self.list = fetchedList
                self.showLoading = false
        }
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
                    loadSiteFiles() // Reload files after import
                    let _ = try sfm.loadSiteFile(siteFileName: selectedFile.lastPathComponent)
                } catch {
                    showSiteFileImportAlert.toggle()
                }
            }
        } catch {
            showSiteFileImportAlert.toggle()
        }
    }
    
    private func handleSiteFileSelection(item: SiteFile) {
        logger.log(type: .info, "Selected site \(item)")
        selectedSiteLocalName = item.localName
        do {
            let _ = try sfm.loadSiteFile(siteFileName: item.localName)
            dismiss()
        } catch {
            showSiteFileImportAlert.toggle()
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
            WebDAV().filesCache.removeAll()
            sfm.siteFile = SiteData()
            sfm.floorImage = UIImage()
            selectedSiteLocalName = nil
            
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
