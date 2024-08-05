//
//  Strings.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.07.24.
//

struct Strings {
    struct Names {
        static let appName = "Pinpoint Developer"
        static let subtitle = ""
        static let sitefile = "Sitefile"
        static let tracelet = "Tracelet"
        static let satlet = "Satlet"
    }

    struct Toasts {
        static let noTraceletInRange = "No Tracelet in range"
        static let traceletConnected = "Tracelet connected"
        static let traceletDisconnected = "Tracelet disconnected"
        static let noAccount = "No Pinpoint Account configured"
        static let loading = "Loading"
        static let error = "Error"
    }
    
    struct Settings {
        static let title = "Settings"
        
        struct General {
            static let loadFloorplanPrompt = "Load a floorplan to enable option"
            static let showGrid = "Show Grid"
            static let showOrigin = "Show Origin"
            static let showAccuracy = "Show Accuracy"
            static let showSatlets = "Show Satlets"
            static let disconnect = "Disconnect"
            static let logToFile = "Log to file"
            
        }
        
        struct Account {
            static let title = "Pinpoint Account"
            static let server = "Server"
            static let username = "Username"
            static let password = "Password"
            static let account =  "Account"
        }
        
        struct Tracelet {
            static let title = "Tracelet Settings"
            static let selectChannel = "Select a channel"
            static let legacyMode = "Legacy Mode"
            static let channel = "Channel"
            static let channel5 = "Channel 5"
            static let channel9 = "Channel 9"
        }
        
        struct Contact {
            static let title = "Contact"
            static let visitUs = "Visit us at Pinpoint.de"
            static let website = "https://pinpoint.de"
            static let privacyPolicy = "Privacy Policy"
            static let privacyPolicyUrl = "https://easylocate.gitlab.io/easylocate-mobile-app/"
            static let version = "Version"
        }
    }

    struct Messages {
        static let folderCreated = "Folder created"
        static let found = "Found"
        static let movedJSONFile = "Moved JSON file from"
        static let to = "to"
        static let renamedAndMovedImageFile = "Renamed and moved image file from"
        static let sitefileLoaded = "Sitefile loaded:"
        static let loadedFloormap = "Loaded Floormap:"
        static let fileSavedSuccessfully = "file saved successfully at:"
    }
    
    
    struct Errors {
        static let network = "Unable to connect. Please try again."
        static let generic = "Something went wrong. Please try again later."
        static let unzipError = "Unzip error:"
        static let generalError = "Error:"
        static let moveJSONFileError = "Error while moving JSON file from"
        static let renameAndMoveImageFileError = "Error while renaming and moving image file from"
        static let decodeJSONError = "Error decoding JSON:"
        static let jsonFileNotFound = "JSON file not found:"
        static let loadLocalImageError = "error loading local image"
        static let loadJSONError = "error loading json:"
        static let loadImageError = "Error loading image:"
        static let noFloorplanFound = "No floorplan image found"
        static let domain = "YourErrorDomain"
        static let getDocumentsDirectoryError = "Error getting documents directory."
        static let createSitesDirectoryError = "Error creating sites directory:"
        static let listFilesError = "Could not list files in directory. Resources = nil, Dir-Path:"
        static let createDirectoryError = "Error creating directory:"
        static let downloadOrSaveFileError = "Error downloading or saving file:"
        static let listDirectoryError = "Error listing directory or downloading files:"
        static let parsingXMLResponseError = "Error parsing XML response"
    }
}

