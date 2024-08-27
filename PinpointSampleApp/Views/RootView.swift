//
//  RootView.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 04.08.23.
//
import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import AlertToast
import CodeScanner

struct RootView: View {
    @ObservedObject var api = EasylocateAPI.shared
    @ObservedObject var sfm = SiteFileManager.shared
    @ObservedObject var alerts = AlertController.shared
    @ObservedObject var storage = LocalStorageManager.shared
    @State private var logViewPresented = false
    @State private var settingsPresented = false
    @State private var codeScannerPresented = false
    @State private var isDownloadingSiteData = false
    @State private var settings: Settings = Settings.shared
    var body: some View {
        NavigationStack{
            ZStack{
                FloorMapView()
                if isDownloadingSiteData {
                    ProgressView()
                }
            }

            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack{
                        Image("pinpoint-circle")
                            .resizable()
                            .frame(width: 30 , height: 30)
                        Text(Strings.Names.appName)
                            .font(.headline)
                            .foregroundColor(CustomColor.pinpoint_gray)
                    }
                    .onTapGesture{
                        logViewPresented = true
                    }
                    .sheet(isPresented: $logViewPresented) {
                        LogView()
                    }
                }
            }
            .toolbarBackground(
                Color.orange.opacity(0.9),
                for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settingsPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(CustomColor.pinpoint_gray)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        codeScannerPresented = true
                    } label: {
                        Image(systemName: "qrcode")
                            .foregroundColor(CustomColor.pinpoint_gray)
                    }
                }
                
            }
            .sheet(isPresented: $settingsPresented) {
                SettingsView()
            }
            
            .sheet(isPresented: $codeScannerPresented) {
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }

            // AlertToast
            .toast(isPresenting: $alerts.showNoTraceletInRange){
                AlertToast(type: .regular, title: Strings.Toasts.noTraceletInRange)
            }
            .toast(isPresenting: $alerts.showConnectedToast){
                AlertToast(type: .complete(.green), title: Strings.Toasts.traceletConnected)
            }
            .toast(isPresenting: $alerts.showDisconnectedToast){
                AlertToast(type: .error(.red), title: Strings.Toasts.traceletDisconnected)
            }
            .toast(isPresenting: $alerts.showLoading){
                AlertToast(type: .loading, title: Strings.Toasts.loading)
            }
            
        }
        
    }
    
    //  isDownloadSuccessful = await sfm.downloadAndSave(site: site)
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        codeScannerPresented = false
        switch result {
        case .success(let scanResult):
            let scannedString = scanResult.string
            
            // Convert the scanned string into Data to decode it
            if let jsonData = scannedString.data(using: .utf8) {
                do {
                    let site = try JSONDecoder().decode(QrCodeData.self, from: jsonData)
                    let baseURLString = Constants.Paths.pinpointServer
                    
                    // Remove the base URL to get the directory path
                    let dirPath = site.sitePath.replacingOccurrences(of: baseURLString, with: "")
                    let account = Account(username: site.user, password: site.pw, baseURL: baseURLString, dirPath: dirPath)
                    
                    // Download the site
                    Task {
                        isDownloadingSiteData = true
                        let success = await sfm.downloadSiteFromQrCode(account: account)
                        if success {
                            // Select the downloaded site
                            print("Downloaded successfully")
                            guard let siteName = URL(string: dirPath)?.lastPathComponent else {
                                return
                            }
                            try sfm.loadSiteFile(siteFileName: siteName)
                            isDownloadingSiteData = false
                            
                        } else {
                            isDownloadingSiteData = false
                            print("Error downloading site file")
                        }
                    }
                    
                } catch {
                    isDownloadingSiteData = false
                    print("Decoding failed: \(error.localizedDescription)")
                }
            } else {
                isDownloadingSiteData = false
                print("Failed to convert scanned string to Data.")
            }
            
        case .failure(let error):
            isDownloadingSiteData = false
            print("Scanning failed: \(error.localizedDescription)")
        }
        
    }

    

    
}

#Preview(body: {
    RootView()
})
