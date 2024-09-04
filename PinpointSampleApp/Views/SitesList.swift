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
    private let itemWidth: CGFloat = 300.0
    
    @AppStorage("selectedSiteLocalName") private var selectedSiteLocalName: String?
    
    var selectedItem: SiteFile? {
        if let localName = selectedSiteLocalName {
            return list.first(where: { $0.localName == localName })
        }
        return nil
    }
    
    var groupedSiteFiles: [String: [SiteFile]] {
        Dictionary(grouping: list, by: { $0.siteData.map.mapName })
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
        .navigationTitle("Import Site")
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
        List {
            ForEach(groupedSiteFiles.keys.sorted(), id: \.self) { mapName in
                if let sites = groupedSiteFiles[mapName] {
                    VStack(alignment: .center, spacing: 2) {
                        Text(mapName)
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            LazyHStack(spacing: 10.0) {
                                ForEach(sites.indices, id: \.self) { index in
                                    CardView(site: sites[index], onSelect: handleSiteFileSelection)
                                        .frame(width: itemWidth, height: 400.0)
                                }
                            }
                            .padding(.horizontal, 10)
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        
    }
    
    
    
    
    
    
    
    
    // CardView for  site information
    struct CardView: View {
        let site: SiteFile
        var onSelect: (SiteFile) -> Void
        
        var body: some View {
            VStack(alignment: .leading) {
                // Header with config name
                Text(site.siteData.map.configName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                
                // Image Section
                Image(uiImage: site.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 4)
                    .padding(.bottom, 4)
                
                // Information Section
                VStack(alignment: .leading, spacing: 8) {
                    // Site ID and Level
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.orange)
                        Text("SiteID: \(site.siteData.map.mapSiteId)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text("Level: \(site.siteData.map.levelName)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    // UWB Channel Information
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        Text("UWB-Channel: \(String(site.siteData.map.uwbChannel ?? Constants.Values.defaultUwbChannel))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    
                }
                .padding(.bottom, 10)
                
                // Load Button
                Button(action: {
                    onSelect(site) 
                }) {
                    Text("Load Site")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
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
        
        Task {
            let fetchedList = sfm.getSitefilesList()
            var updatedList: [SiteFile] = []
            
            for var siteFile in fetchedList {
                do {
                    let image = try sfm.getFloorImage(siteFileName: siteFile.localName)
                    siteFile.image = image
                } catch {
                    logger.log(type: .error, "Failed to load image for site \(siteFile.localName): \(error)")
                    siteFile.image = UIImage(systemName: "exclamationmark.triangle") ?? UIImage()
                }
                updatedList.append(siteFile)
            }
            
            DispatchQueue.main.async {
                self.list = updatedList
                self.showLoading = false
            }
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
                    loadSiteFiles()
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
            let _ = try sfm.loadSiteFile(siteFileName: item.localName, setSite: true)
            dismiss()
        } catch {
            showSiteFileImportAlert.toggle()
        }
    }
    
    func clearCache() {
        let fileManager = FileManager.default
        do {
            let documentDirectoryURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in fileURLs {
                try fileManager.removeItem(at: url)
            }
            list.removeAll()
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
