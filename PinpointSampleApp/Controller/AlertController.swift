//
//  AlertController.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 15.08.23.
//

import Foundation
import AlertToast

class AlertController:ObservableObject {
    
    public static let shared = AlertController()

    @Published var showConnectedToast = false
    @Published var showDisconnectedToast = false
    @Published var showNoTraceletInRange = false
    @Published var showNoWebDavAccount = false
    @Published var showLoading = false
    
    private init() {}
   
}
