//
//  Settings.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 28.08.23.
//

import SwiftUI
import Pinpoint_Easylocate_iOS_SDK

struct SettingsView: View {
    @State var mapSettings = Settings.shared
    @Environment(\.presentationMode) var presentationMode
    @State var updatedTraceletID:String = ""
    @ObservedObject var api = EasylocateAPI.shared
    @ObservedObject var sfm = SiteFileManager.shared
    @State var status = TraceletStatus()
    @State var version = ""
    @State var interval: Int = 1
    @State private var showIntervalSettings = false
    @State private var showChannelAlert = false
    let logger = Logging.shared
    
    @StateObject var storage = LocalStorageManager.shared
    @StateObject var config = Config.shared
    
    
    var body: some View {
        @State var role = parseRole(byte: Int8(status.role) ?? 0)
        
        NavigationStack {
            Form {
                Section(header: Text(Strings.Settings.title)) {
                    
                    if api.connectionState == .CONNECTED {
                        Button{
                            disconnect()
                        } label: {
                            Text(Strings.Settings.General.disconnect)
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                        }
                    }
                    
                    if !siteFileLoaded() {
                        Text(Strings.Settings.General.loadFloorplanPrompt)
                            .foregroundColor(.red)
                    }
                    
                    Toggle(isOn: $mapSettings.showOrigin) {
                        Text(Strings.Settings.General.showOrigin)
                    }
                    .disabled(!siteFileLoaded())
                    
                    Toggle(isOn: $mapSettings.showAccuracyRange) {
                        Text(Strings.Settings.General.showAccuracy)
                    }
                    .disabled(!siteFileLoaded())
                    
                    Toggle(isOn: $mapSettings.showSatlets) {
                        Text(Strings.Settings.General.showSatlets)
                    }
                    .disabled(!siteFileLoaded())
                    
                }
                
                
                
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
                
                Section(header: Text(Strings.Settings.Tracelet.title)) {
                    
                    HStack {
                        Picker(Strings.Settings.Tracelet.selectChannel, selection: $storage.channel) {
                            Text(Strings.Settings.Tracelet.channel5).tag(5)
                            Text(Strings.Settings.Tracelet.channel9).tag(9)
                        }
                        .pickerStyle(.automatic)
                        
                        .onChange(of: storage.channel) { newValue in
                            Task {
                                let success = api.setChannel(channel: Int8(newValue))
                                api.startPositioning()
                            }
                        }

                        Spacer()
                    }
                    
                    Toggle(Strings.Settings.Tracelet.legacyMode, isOn: Binding<Bool>(
                        get: {
                            !config.uci
                        },
                        set: {
                            config.uci = !$0
                        }
                    ))
                    
                    Toggle(isOn: $config.logToFile, label: {
                        Text(Strings.Settings.General.logToFile)
                    })
                    
                }
                .task {
                    do {
                        status = try await getStatus()
                        version = await getVersion()
                        logger.log(type: .info, version)
                        logger.log(type: .info, status.address)
                    } catch {
                        logger.log(type: .warning, error.localizedDescription)
                    }
                }
                
                Section(header: Text(Strings.Settings.Contact.title)) {
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    Link(Strings.Settings.Contact.visitUs, destination: URL(string: Strings.Settings.Contact.website)!)
                    Link(Strings.Settings.Contact.privacyPolicy, destination: URL(string: Strings.Settings.Contact.privacyPolicyUrl)!)
                    Text("\(Strings.Settings.Contact.version): \(appVersion ?? "n/a")")
                        .font(.caption)
                }
            }
            .navigationTitle(Strings.Settings.title)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .presentationDragIndicator(.visible)
    }
    
    
    func siteFileLoaded() -> Bool {
        return sfm.siteFile.map.mapName != ""
    }
    
    
    func getStatus() async throws -> TraceletStatus {
        if let status = await api.getStatus() {
            return status
        } else {
            throw CustomError.statusNotFound
        }
    }
    
    func disconnect() {
        api.disconnect()
    }
    
    func getVersion() async -> String {
        if let version = await api.getVersion() {
            return version
        } else {
            return ""
        }
    }
    
}


#Preview(body: {
    SettingsView()
})
