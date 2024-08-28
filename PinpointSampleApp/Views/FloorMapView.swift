//
//  FloorMapView.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 19.04.23.
//

import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import CoreBluetooth
import AlertToast

struct FloorMapView: View {
    @ObservedObject var api = EasylocateAPI.shared
    @ObservedObject var sfm = SiteFileManager.shared
    @ObservedObject var alerts = AlertController.shared
    @ObservedObject var storage = LocalStorageManager.shared
    @StateObject var tracelet = Tracelet.shared

    
    @State private var centerAnchor: Bool = false
    @State private var currentPosition = CGPoint()
    @State private var discoveredDevices: [CBPeripheral] = []
    @State private var finalScale: CGFloat = 1.0
    @State private var finalTranslation: CGSize = .zero
    @State private var image = UIImage()
    @State private var imageGeo: ImageGeometry = ImageGeometry(xOrigin: 0.0, yOrigin: 0.0, imageSize: .zero, imagePosition: .zero)
    @State private var meterToPixelRatio: CGFloat = 0.0
    @State private var scale = 0.6
    @State private var settings: Settings = Settings.shared
    
    @State private var showAlert = false
    @State private var showingScanResults = false
    @State private var siteListIsPresented = false
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureTranslation: CGSize = .zero
    
    let logger = Logging.shared
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading) {
                ScrollViewReader { scrollView in
                    ScrollView([.horizontal, .vertical]) {
                        if api.scanState == .SCANNING {
                            HoldDeviceCloseView()
                        } else {
                            if !isSiteFileLoaded() {
                                NoMapLoadedView(siteListIsPresented: $siteListIsPresented)
                            }
                            
                            Image(uiImage: image)
                                .resizable()
                                .border(Color("pinpoint_gray"), width: 2)
                                .id("imagecenter")
                                .onAppear {
                                    handleOnAppear()
                                }
                                .onChange(of: centerAnchor) { newCenterAnchor in
                                    handleCenterAnchorChange(newCenterAnchor, scrollView: scrollView)
                                }
                                .onChange(of: api.connectionState) { newValue in
                                    handleConnectionStateChange(newValue)
                                }
                                .onChange(of: sfm.siteFile) { newValue in
                                    handleSiteFileChange(newValue)
                                    scrollView.scrollTo("imagecenter", anchor: .center)
                                }
                                .overlay {
                                    overlayContent()
                                }
                                .scaleEffect(scale)
                                .pinchToZoom()
                        }
                    }
                }
            }
            
            VStack(alignment: .trailing) {
                ButtonStack(scanAction: {
                    Task {
                        await scan()
                    }
                }, centerAction: {
                    centerImage()
                }, siteListAction: {
                    siteListIsPresented.toggle()
                }, size: 50)
            }
            .offset(y: -10)
            .padding(.vertical)
        }

        .sheet(isPresented: $showingScanResults) {
            DeviceListView(discoveredDevices: $discoveredDevices)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $siteListIsPresented) {
            SitesList()
        }
    }
    
    func centerImage() {
        centerAnchor.toggle()
    }
    
    // Function to handle view's onAppear event
    private func handleOnAppear() {
        imageGeo.imageSize = CGSize(width: image.size.width, height: image.size.height)
        centerAnchor.toggle()
    }

    // Function to handle centerAnchor onChange event
    private func handleCenterAnchorChange(_ newCenterAnchor: Bool, scrollView: ScrollViewProxy) {
        scrollView.scrollTo("imagecenter", anchor: .center)
        scale = 0.6
    }


    // Function to handle api.connectionState onChange event
    private func handleConnectionStateChange(_ newValue: ConnectionState) {
        if newValue == .CONNECTED {
            if !sfm.siteFile.map.mapName.isEmpty {
                _ = api.setChannel(channel: Int8(sfm.siteFile.map.uwbChannel))
            }
            alerts.showConnectedToast.toggle()
        } else if newValue == .DISCONNECTED {
            alerts.showDisconnectedToast.toggle()
        }
    }

    // Function to handle sfm.siteFile onChange event
    private func handleSiteFileChange(_ newValue: SiteData?) {
        if let newSiteFile = newValue {
            updateSiteFile(with: newSiteFile)
        }
    }

    // Function to encapsulate overlay logic
    private func overlayContent() -> some View {
        Group {
            if settings.showOrigin {
                OriginIndicator()
                    .position(placeOrigin())
            }
            
            // MARK: - PositionTrace
            if isSiteFileLoaded() && isConnected() {
                PositionTraceView(
                    meterToPixelRatio: $meterToPixelRatio,
                    imageGeo: $imageGeo,
                    settings: $settings,
                    circlePos: $currentPosition
                )
            }
            
            if settings.showSatlets {
                SatletView(imageGeo: $imageGeo, siteFile: $sfm.siteFile)
            }
        }
    }
    
    
    // Function to check if connected
    private func isConnected() -> Bool {
        return api.connectionState == .CONNECTED
    }

    // Function to check if mapName is not empty
    private func isSiteFileLoaded() -> Bool {
        return !sfm.siteFile.map.mapName.isEmpty
    }

    // Function to update the site file
    private func updateSiteFile(with newSiteFile: SiteData) {
        image = sfm.floorImage
        imageGeo.xOrigin = newSiteFile.map.mapFileOriginX
        imageGeo.yOrigin = newSiteFile.map.mapFileOriginY
        meterToPixelRatio = newSiteFile.map.mapFileRes
        imageGeo.imageSize = CGSize(width: image.size.width, height: image.size.height)
        imageGeo.imagePosition = CGPoint.zero
        
        _ = api.setChannel(channel: Int8(newSiteFile.map.uwbChannel))
        storage.channel = Int(newSiteFile.map.uwbChannel)
        api.startPositioning()
    }


    
    func scan() async {
        let discoveredTracelets = await tracelet.scan()
        
        if discoveredTracelets.isEmpty {
            showAlertNoTraceletsFound()
            return
        }
        
        if discoveredTracelets.count > 1 {
            toggleScanResults()
        } else if let onlyDevice = discoveredTracelets.first {
            await connectToTracelet(onlyDevice)
        }
    }
    
    @MainActor
    private func showAlertNoTraceletsFound() {
        alerts.showNoTraceletInRange = true
    }
    
    @MainActor
    private func toggleScanResults() {
        showingScanResults.toggle()
    }
    
    private func connectToTracelet(_ tracelet: CBPeripheral) async {
        let success = await self.tracelet.startTracelet(tracelet: tracelet, channel: sfm.siteFile.map.uwbChannel)
        if success {
            print("Successfully connected to and configured tracelet: \(tracelet)")
        } else {
            print("Failed to connect to and configure tracelet: \(tracelet)")
        }
    }
    
    private func updateImagePosition() {
        let positionX = finalTranslation.width + gestureTranslation.width
        let positionY = finalTranslation.height + gestureTranslation.height
        DispatchQueue.main.async {
            imageGeo.imagePosition = CGPoint(x: positionX, y: positionY)
        }
    }
    
    private func placeOrigin() -> CGPoint {
        let scaledX = imageGeo.xOrigin * meterToPixelRatio
        let scaledY = imageGeo.imageSize.height - (imageGeo.yOrigin * meterToPixelRatio)
        
        return CGPoint(x: scaledX, y: scaledY)
    }
}

#Preview {
    FloorMapView()
}

struct HoldDeviceCloseView: View {
    var body: some View {
        VStack {
            Image("contactless-icon")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
            ProgressView("Hold Tracelet close to phone")
        }
    }
}

struct NoMapLoadedView: View {
    @Binding var siteListIsPresented: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Image(systemName: "map.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                Capsule()
                    .frame(width: 135, height: 10)
                    .rotationEffect(Angle(degrees: 145))
            }
            .foregroundColor(CustomColor.pinpoint_gray)
            
            Text("No floor plan loaded")
                .font(.headline)
                .padding()
            Spacer()
                .frame(height: 50)
            Button {
                siteListIsPresented.toggle()
            } label: {
                Text("Load floor plan")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
