//
//  RemoteSitesList.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 23.06.23.
//

import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import WebDAV



struct RemoteSitesList: View {
    @EnvironmentObject var sfm:SiteFileManager
    @EnvironmentObject var alerts : AlertController
    @StateObject var storage = LocalStorageManager.shared
    @State private var sites = [String]()
    @State private var selectedSite: String?
    @State private var isDownloadSuccessful = true
    @State private var isLoading = true
    @State private var showSettings = false
    @Environment(\.dismiss) var dismiss
    
    
    
    var body: some View {
        ZStack{
            
            VStack{
                Text("Available Maps")
                    .font(.headline)
                    .padding()
                
                // Show Loading Activity
                if isLoading {
                    ProgressView()
                }
                
                // Show Empty List
                if sites.isEmpty && !isLoading {
                    VStack {
                        Image(systemName: "square.3.layers.3d.slash")
                            .resizable()
                            .scaledToFill()
                            .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
                        Text("Can`t connect to Pinpoint-Account")
                            .font(.headline)
                        Text("Check your credentials")
                            .font(.footnote)
                        WebDavCreds()
                        Button("Save credentials"){
                            loadWebDavSites()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                    }
                    // Show Sites List
                } else {
                    List(sites, id: \.self) { site in
                        if let url = URL(string: site) {
                            Button(url.lastPathComponent) { // Use lastPathComponent as the label
                                Task {
                                    isDownloadSuccessful = false
                                    isDownloadSuccessful = await sfm.downloadAndSave(site: site)
                                    dismiss()
                                }
                            }
                        } else {
                            Text("Invalid URL: \(site)")
                        }
                    }
                    .scrollContentBackground(.hidden)
  
                }
            }
            
            if !isDownloadSuccessful {
                Color.gray
                    .opacity(0.5)
                ProgressView()
                
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear() {
            loadWebDavSites()
        }
        
    }
    
    func loadWebDavSites() {
        Task{
            do {
                isLoading = true
                if let foundSites = try await NextcloudFileLister().listFilesInNextcloudFolder() {
                    sites = foundSites
                } else {
                    print("nothing found")
                }
            } catch {
                print(error)
            }
            isLoading = false
        }
    }
    
}

struct WebDavCreds: View {
    @StateObject var storage = LocalStorageManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack{
            
            Form{
                Section(header: Text(Strings.Settings.Account.title)) {
                    VStack(alignment: .leading){
                        Text(Strings.Settings.Account.username)
                            .font(.footnote)
                        TextField(Strings.Settings.Account.username, text: $storage.webdavUser)
                    }
                    VStack(alignment: .leading){
                        Text(Strings.Settings.Account.password)
                            .font(.footnote)
                        TextField(Strings.Settings.Account.password, text: $storage.webdavPW)
                    }
                }
            }
        }
    }
}


struct Account:WebDAVAccount {
    var username: String?
    var baseURL: String?
    
}


struct RemoteSitesList_Previews: PreviewProvider {
    static var previews: some View {
        RemoteSitesList()
    }
}

