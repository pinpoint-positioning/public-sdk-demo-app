//
//  SiteFileManager.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.05.23.
//

import Foundation
import ZIPFoundation
import SwiftUI
import Pinpoint_Easylocate_iOS_SDK
import WebDAV

public class SiteFileManager: ObservableObject {
    public static let shared = SiteFileManager()
    private var storage = LocalStorageManager.shared
    private let logger = Logging.shared
    private let fileManager = FileManager()
    
    @Published var siteFile = SiteData()
    @Published var floorImage = UIImage()
    
    private init() {}

    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    public func unarchiveFile(sourceFile: URL) async throws {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent(Constants.Paths.sitefiles)

        var sourceFileName = sourceFile.lastPathComponent
        if sourceFileName.lowercased().hasSuffix(Constants.Extensions.zip) {
            sourceFileName = String(sourceFileName.dropLast(4))
        }

        destinationURL.appendPathComponent(sourceFileName)

        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            print(Strings.Messages.folderCreated)
            try fileManager.unzipItem(at: sourceFile, to: destinationURL)
            try await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)

            if let items = moveAndRenameFiles(path: destinationURL) {
                for item in items {
                    print("\(Strings.Messages.found) \(item)")
                }
            }
        } catch {
            print("\(Strings.Errors.unzipError) \(error)")
            throw (error)
        }
    }

    public func getMapName(from fileURL: URL) throws -> String {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(SiteData.self, from: data)
            return jsonData.map.mapName
        } catch {
            print("\(Strings.Errors.generalError) \(error)")
            throw error
        }
    }

    public func getSitefilesList() -> [String] {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent(Constants.Paths.sitefiles)
        var list = [String]()

        do {
            let items = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
            for item in items {
                print(item)
                list.append(item)
            }
        } catch {
            print(error)
        }
        return list
    }

    func moveAndRenameFiles(path: URL) -> [String]? {
        let imageFileTypes = Constants.Extensions.imageFileTypes

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path.path)

            for item in items {
                let fileType = NSURL(fileURLWithPath: item).pathExtension
                if let fileType = fileType {
                    switch fileType.lowercased() {
                    case Constants.Extensions.json:
                        do {
                            try fileManager.moveItem(atPath: path.appendingPathComponent(item).path, toPath: path.appendingPathComponent(Constants.FileNames.sitedata).path)
                            logger.log(type: .info, "\(Strings.Messages.movedJSONFile) \(path.appendingPathComponent(item).path) \(Strings.Messages.to) \(path.appendingPathComponent(Constants.FileNames.sitedata).path)")
                        } catch {
                            logger.log(type: .error, "\(Strings.Errors.moveJSONFileError) \(path.appendingPathComponent(item).path): \(error)")
                        }
                    case let type where imageFileTypes.contains(type):
                        do {
                            let newFileName = "\(Constants.FileNames.floorplan).\("\(fileType)")"
                            try fileManager.moveItem(atPath: path.appendingPathComponent(item).path, toPath: path.appendingPathComponent(newFileName).path)
                            logger.log(type: .info, "\(Strings.Messages.renamedAndMovedImageFile) \(path.appendingPathComponent(item).path) \(Strings.Messages.to) \(path.appendingPathComponent(newFileName).path)")
                        } catch {
                            logger.log(type: .error, "\(Strings.Errors.renameAndMoveImageFileError) \(path.appendingPathComponent(item).path): \(error)")
                        }
                    default:
                        break
                    }
                }
            }
            return items
        } catch {
            print(error)
            return nil
        }
    }

    func loadSiteFile(siteFileName: String) throws {
        var fileNameWithoutExtension = siteFileName
        if siteFileName.lowercased().hasSuffix(Constants.Extensions.zip) {
            fileNameWithoutExtension = String(siteFileName.dropLast(4))
        }

        siteFile = loadJson(siteFileName: fileNameWithoutExtension)
        do {
            logger.log(type: .info, "\(Strings.Messages.sitefileLoaded) \(fileNameWithoutExtension)")
            floorImage = try getFloorImage(siteFileName: fileNameWithoutExtension)
        } catch {
            throw error
        }
    }

    func loadLocalSiteFile(siteFileName: String) {
        siteFile = loadLocalJson(siteFileName: siteFileName)
        if let localImage = getLocalFloorImage(siteFileName: siteFileName) {
            logger.log(type: .info, "\(Strings.Messages.sitefileLoaded) \(siteFileName)")
            floorImage = localImage
        }
    }

    public func loadLocalJson(siteFileName: String) -> SiteData {
        if let asset = NSDataAsset(name: "\(siteFileName).\(Constants.Extensions.json)", bundle: Bundle.main) {
            do {
                let jsonData = try JSONDecoder().decode(SiteData.self, from: asset.data)
                return jsonData
            } catch {
                logger.log(type: .error, "\(Strings.Errors.decodeJSONError) \(error)")
            }
        } else {
            logger.log(type: .error, "\(Strings.Errors.jsonFileNotFound) \(siteFileName)")
            return SiteData()
        }
        return SiteData()
    }

    public func getLocalFloorImage(siteFileName: String) -> UIImage? {
        if let image = UIImage(named: siteFileName) {
            return image
        } else {
            logger.log(type: .error, Strings.Errors.loadLocalImageError)
            return nil
        }
    }

    public func loadJson(siteFileName: String) -> SiteData {
        do {
            print(siteFileName)
            var destinationURL = getDocumentsDirectory()
            print(destinationURL)
            destinationURL.appendPathComponent(Constants.Paths.sitefiles)
            print(destinationURL)
            destinationURL.appendPathComponent(siteFileName)
            print(destinationURL)

            let data = try Data(contentsOf: destinationURL.appendingPathComponent(Constants.FileNames.sitedata))
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(SiteData.self, from: data)
            return jsonData
        } catch {
            logger.log(type: .error, "\(Strings.Errors.loadJSONError) \(error)")
            return SiteData()
        }
    }

    
    public func getFloorImage(siteFileName: String) throws -> UIImage {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent(Constants.Paths.sitefiles)
        destinationURL.appendPathComponent(siteFileName)

        let floorplanFiles = try FileManager.default.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.lowercased().hasPrefix(Constants.FileNames.floorplan) }

        guard let floorplanFile = floorplanFiles.first else {
            throw NSError(domain: Strings.Errors.domain, code: 0, userInfo: [NSLocalizedDescriptionKey: Strings.Errors.noFloorplanFound])
        }

        do {
            let imageData = try Data(contentsOf: floorplanFile)
            logger.log(type: .info, "\(Strings.Messages.loadedFloormap) \(imageData)")
            return UIImage(data: imageData) ?? UIImage()
        } catch {
            logger.log(type: .info, "\(Strings.Errors.loadImageError) \(error)")
            throw error
        }
    }

    
    
    

    public func listRemoteFiles() async throws -> [String]? {
        let wd = WebDAV()
        let remoteSitesDir = "\(Constants.Paths.davFiles)\(storage.webdavUser)\(Constants.Paths.sitesSchema)"
        let account = Account(username: storage.webdavUser, password: storage.webdavPW, baseURL: Constants.Paths.pinpointServer)
        
        return try await withCheckedThrowingContinuation { continuation in
            wd.listFiles(atPath: remoteSitesDir, account: account, password: account.password ?? "", includeSelf: false) { resources, error in
                if let error = error {
                    self.logger.log(type: .error, "Error: \(error)")
                    continuation.resume(throwing: error) // Resume with error if an error occurs
                    return
                }
                
                guard let resources = resources else {
                    self.logger.log(type: .error, "\(Strings.Errors.listFilesError) \(remoteSitesDir)")
                    continuation.resume(returning: nil) // Resume with nil if resources are nil
                    return
                }
                
                var remoteSitesList = [String]()
                for resource in resources {
                    if resource.isDirectory {
                        let siteFilePath = "\(remoteSitesDir)/\(resource.fileName)"
                        remoteSitesList.append(siteFilePath)
                    }
                }
                
                continuation.resume(returning: remoteSitesList) // Resume with the list of remote sites
            }
        }
        
    }

    
    
    
    public func downloadAndSave(site: String) async -> Bool {
        let account = Account(username: storage.webdavUser, password: storage.webdavPW, baseURL: Constants.Paths.pinpointServer)
        let directoryURL = site.removingPercentEncoding ?? site

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.log(type: .error, Strings.Errors.getDocumentsDirectoryError)
            return false
        }

        let sitesDirectory = documentsDirectory.appendingPathComponent(Constants.Paths.sitefiles)
        do {
            try FileManager.default.createDirectory(at: sitesDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log(type: .error, "\(Strings.Errors.createSitesDirectoryError) \(error)")
            return false
        }

        return await downloadAndProcessFiles(from: directoryURL, to: sitesDirectory, account: account)
    }
    
    
    
    public func downloadSiteFromQrCode(account: Account) async -> Bool {
       
        // Safely unwrap the baseURL and remove percent encoding
        guard let directoryURLString = account.dirPath,
              let directoryURL = URL(string: directoryURLString.removingPercentEncoding ?? directoryURLString) else {
            logger.log(type: .error, "Invalid URL in base URL or failed to remove percent encoding.")
            return false
        }

        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.log(type: .error, Strings.Errors.getDocumentsDirectoryError)
            return false
        }

        // Create the sites directory path
        let dirName = directoryURL.lastPathComponent
        let sitesDirectory = documentsDirectory.appendingPathComponent("\(Constants.Paths.sitefiles)/\(dirName)")
        
        do {
            // Create the directory if it doesn't exist
            try FileManager.default.createDirectory(at: sitesDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log(type: .error, "\(Strings.Errors.createSitesDirectoryError) \(error)")
            return false
        }

        // download and process files
        return await downloadAndProcessFiles(from: directoryURL.absoluteString, to: sitesDirectory, account: account)
    }
    
    
    

    private func downloadAndProcessFiles(from remotePath: String, to localURL: URL, account: Account) async -> Bool {
        let wd = WebDAV()
        do {
            let resources = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<[WebDAVFile]?, Error>) in
                wd.listFiles(atPath: remotePath, account: account, password: account.password ?? "", includeSelf: false) { resources, error in
                    
                    if let error = error {
                        self.logger.log(type: .error, "Error: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: resources)
                    }
                }
            }

            guard let resources = resources else {
                logger.log(type: .error, "\(Strings.Errors.listFilesError) \(remotePath)")             
                return false
            }

            for resource in resources {
                if resource.isDirectory {
                    let newLocalURL = localURL.appendingPathComponent(resource.fileName)
                    logger.log(type: .info, "Found:  \(remotePath) ")
                    do {
                        try FileManager.default.createDirectory(at: newLocalURL, withIntermediateDirectories: true, attributes: nil)
                        logger.log(type: .info, "Dir created:  \(newLocalURL) ")
                    } catch {
                        logger.log(type: .error, "\(Strings.Errors.createDirectoryError) \(error)")
                        return false
                    }
                    if !(await downloadAndProcessFiles(from: resource.path, to: newLocalURL, account: account)) {
                        return false
                    }
                    // Do not download zip files
                } else if !resource.fileName.hasSuffix(".zip") {
                    let fileURL = localURL.appendingPathComponent(resource.fileName)
                    do {
                        let data = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Data?, Error>) in
                            wd.download(fileAtPath: resource.path, account: account, password: account.password ?? "") { data, error in
                                if let error = error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: data)
                                }
                            }
                        }

                        if let data = data {
                            logger.log(type: .info, "Saving:  \(fileURL) ")
                            try data.write(to: fileURL)
                            logger.log(type: .info, "\(resource.fileName) \(Strings.Messages.fileSavedSuccessfully) \(fileURL)")
                        } else {
                            return false
                        }

                        let _ = moveAndRenameFiles(path: localURL)
                    } catch {
                        logger.log(type: .error, "\(Strings.Errors.downloadOrSaveFileError) \(error)")
                        return false
                    }
                }
            }

            return true
        } catch {
            logger.log(type: .error, "\(Strings.Errors.listDirectoryError) \(error)")
            return false
        }
    }

    enum WebDAVDownloadError: Error {
        case invalidURL
        case missingJSONFile
        case missingPNGFile
        case downloadFailed
    }
}

public struct FileItem {
    var name: String
    var isFolder: Bool
}

