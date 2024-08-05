//
//  RootView.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 04.08.23.
//
import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import AlertToast

struct RootView: View {
    @StateObject var api = EasylocateAPI.shared
    @StateObject var sfm = SiteFileManager()
    @StateObject var alerts = AlertController()
    @StateObject var storage = LocalStorageManager()
    @State private var isLogViewPresented = false
    var body: some View {
        NavigationStack{
            ZStack{
                FloorMapView()
            }
            .environmentObject(api)
            .environmentObject(sfm)
            .environmentObject(alerts)
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
                        isLogViewPresented = true
                    }
                    .sheet(isPresented: $isLogViewPresented) {
                        LogView()
                    }
                }
            }
             .toolbarBackground(
                Color.orange.opacity(0.9),
                 for: .navigationBar)
             .toolbarBackground(.visible, for: .navigationBar)

            
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
    
    
    struct RootView_Previews: PreviewProvider {
        static var previews: some View {
            RootView()
        }
    }
}
