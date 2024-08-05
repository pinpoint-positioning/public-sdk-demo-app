//
//  ConnectionManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 24.05.24.
//

import Foundation
import Pinpoint_Easylocate_iOS_SDK
import CoreBluetooth


class Tracelet: ObservableObject {

    static let shared = Tracelet()
    let config = Config.shared
    let api = EasylocateAPI.shared

    
    func disconnect() {
        api.disconnect()
    }
    
    func stopScan() {
        api.stopScan()
    }
    
    
    
    func scan() async -> [CBPeripheral] {
        // Ensure the scan only happens if in the appropriate state
        guard api.connectionState == .DISCONNECTED, api.bleState == .BT_OK else {
            return []
        }

        // Use a continuation to bridge the asynchronous callback
        return await withCheckedContinuation { continuation in
            var didResume = false
            
            // Function to safely resume the continuation
            func safeResume(_ deviceList: [CBPeripheral]) {
                if !didResume {
                    continuation.resume(returning: deviceList)
                    didResume = true
                }
            }
            
            // Start scanning
            api.scan(timeout: 3) { deviceList in
                safeResume(deviceList)
            }

        }
    }

    
    func startTracelet(tracelet: CBPeripheral, channel: Int) async -> Bool {
        do {

            let channelSetSuccessful = api.setChannel(channel: Int8(channel))
            if !channelSetSuccessful {
                print("Failed to set channel: \(channel) for device: \(tracelet)")
            }
            
            api.setPositioningInterval(interval: 1)
            
            let connectionSuccessful = try await api.connectAndStartPositioning(device: tracelet)
            guard connectionSuccessful else {
                print("Failed to connect and start positioning for device: \(tracelet)")
                return false
            }

            return channelSetSuccessful
        } catch {
            print("Error while starting tracelet for device: \(tracelet), error: \(error)")
            return false
        }
    }
}
    

