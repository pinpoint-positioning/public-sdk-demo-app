//
//  LocalStorageManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 29.08.23.
//

import Foundation
import SwiftUI

class LocalStorageManager: ObservableObject{
    
    static var shared = LocalStorageManager()
    
    @AppStorage("webdav-user") var webdavUser = ""
    @AppStorage("webdav-pw") var webdavPW = ""
    @AppStorage ("channel")  var channel:Int = 5
}
