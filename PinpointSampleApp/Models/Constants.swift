//
//  Constants.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.07.24.
//

struct Constants {
    struct Paths {
        static let pinpointServer = "https://connect.pinpoint.de"
        static let sitefiles = "sitefiles"
        static let davFiles = "/remote.php/dav/files/"
        static let sitesSchema = "/sites_schema5"
        static let webDavBaseDir = pinpointServer + davFiles
    }

    struct Extensions {
        static let zip = ".zip"
        static let json = "json"
        static let imageFileTypes = ["png", "jpg", "jpeg"]
    }

    struct FileNames {
        static let sitedata = "sitedata.json"
        static let floorplan = "floorplan"
    }

    struct Headers {
        static let authorization = "Authorization"
        static let basic = "Basic "
    }

    struct Methods {
        static let propfind = "PROPFIND"
    }

    struct Elements {
        static let dHref = "d:href"
    }

    struct Keys {
        static let webdavUser = "webdav-user"
        static let webdavPW = "webdav-pw"
    }
}
