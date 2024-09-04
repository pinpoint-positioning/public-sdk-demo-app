//
//  DeviceList.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 07.08.23.
//

import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import CoreBluetooth

struct DeviceListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var api = EasylocateAPI.shared
    @Binding var discoveredDevices:[CBPeripheral]
    @ObservedObject var sfm = SiteFileManager.shared
    let logger = Logging.shared
    @State var eyeIconOpacity = 1.0
    
    var body: some View {
        NavigationView{
            VStack {
                if (api.scanState == .SCANNING) {
                    ProgressView("Scanning...")
                        .padding()
                    
                }
                let _ = print(discoveredDevices)
                let _ = print("DEVICE LIST")
                List{
                    ForEach(discoveredDevices, id: \.self) { device in

                        HStack{
                            Button(device.name ?? "name not found") {
                                Task {
                                    do {
                                        let connectResult = try await api.connectAndStartPositioning(device: device)
                                        if connectResult {
                                            logger.log(type: .info, "ConnectAndStartPositioning OK")
                                        } else {
                                            logger.log(type: .error, "ConnectAndStartPositioning Failed")
                                        }
                                    } catch {
                                        logger.log(type: .error, "ConnectAndStartPositioning Error: \(error.localizedDescription)")
                                    }

                                    let uwbChannel = sfm.siteFile.map.uwbChannel
                                    let channelResult = api.setChannel(channel: Int8(uwbChannel ?? Constants.Values.defaultUwbChannel))

                                    if channelResult {
                                        logger.log(type: .info, "Channel set to \(String(describing: uwbChannel)) ...OK")
                                    } else {
                                        logger.log(type: .error, "SetChannel Failed")
                                    }
                                }
                                dismiss()
                            }
                            .foregroundColor(.black)
                            Spacer()
                            
                            // Eye will fadeInOut when showme is ongoing
                            Image(systemName: "eye")
                                .foregroundColor(.black)
                                .onTapGesture {
                                    // connect and then showme, then disconnect
                                    Task {
                                        do {
                                            try await api.connect(device: device)
                                        } catch {
                                            logger.log(type: .error, error.localizedDescription)
                                        }
                                        api.showMe(tracelet: device)
                                        
                                        
                                        try await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
          
                                        
                                        api.disconnect()
                                    }
                                    
                                        
                                }
                            
                        }
                    
                    }
                }
            }
            .navigationTitle("Nearby Tracelets")
        }
    }

}
