//
//  ResourcesHandler.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/7.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit
import HandyJSON
import CommonCrypto
 

class Resource: HandyJSON {
    var md5: String?
    var version: String?
    var downloadUrl: String? // 资源模板下载 URI
    var name: String? // 资源根目录
    var description: String?
    
    func mapping(mapper: HelpingMapper) {
        mapper.specify(property: &description, name: "desc")
    }
    
    required init() {}
}

enum ResourceVerifiedResult {
    case verified
    case needToDownload
    case needToUnzip
}

@objc(PLResourcesHandler)
public class ResourcesHandler: NSObject {
    
    @objc(shareInstance)
    public static let shared = ResourcesHandler()
    
    let path = "http://192.168.0.183:59191/api/Resource/List"
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    public var resourcesFileUrl: URL {
        let url =  URL(fileURLWithPath: documentPath!).appendingPathComponent("Resources")
        // 确保资源路径已创建
        if FileManager.default.fileExists(atPath: url.path) == false {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
    
    required override init() {
        
    }
    
    // MARK: key for UserDefault
    func keyForZipFileMD5(resourceName: String) -> String {
        return "\(resourceName)_zip_md5"
    }
    func keyForUnzipedFilesMD5s(resourceName: String) -> String {
        return "\(resourceName)_dir_md5"
    }
    
    func loadHTMLSourcesFromService() {
        
        self.loadDataFromURL(urlString: path, success: { responseObject in
            
            let string = String(data: responseObject as! Data, encoding: .utf8)
            
            if let resources = [Resource].deserialize(from: string) {
                self.processResources(resources as! [Resource])
            } else {
                print("无数据")
            }
            
        }) { error in
            
            print(error!.localizedDescription)
        }
        
    }
    
    func processResources(_ resources: [Resource]) {
        
        resources.forEach({ resource in
            // 校验每个 resource
            guard resource.name != nil else {
                return
            }
            let verifiedResult = self.verifyResource(resource)
            
            switch verifiedResult {
            case .verified:
                break
            case .needToDownload:
                self.downloadResource(resource)
            case .needToUnzip:
                let _ = self.unzipResource(resource)
            }
        })
    }
    
    func loadDataFromURL(urlString: String!, success: @escaping (Any?) -> Void, failure: @escaping (Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            guard error == nil else {
                failure(error)
                return
            }
            success(data)
        }
        task.resume()
    }
    
    // MARK: Verify
    func verifyResource(_ resource: Resource) -> ResourceVerifiedResult {
        
        let resourceName = resource.name!
        
        var storedResourceInfo = self.fetchStoredResourceInfoFromUserDefault(resourceName, createInfoIfNotExist: false)
        let kZipFileMD5 = self.keyForZipFileMD5(resourceName: resourceName)
        let kOriginalUnzipedFilesMD5s = self.keyForUnzipedFilesMD5s(resourceName: resourceName)
        
        if storedResourceInfo != nil {
            
            // Verify 1：校验服务器zip包的MD5 与 本地zip包的MD5
            if let storedZipMD5 = storedResourceInfo![kZipFileMD5] as? String,
                storedZipMD5 == resource.md5 {
                
                // Verify 2：校验当前zip包子文件的MD5 与 初次解压的zip包子文件的MD5
                if let originalUpzipedFilesMD5s = storedResourceInfo![kOriginalUnzipedFilesMD5s] as? [String],
                    originalUpzipedFilesMD5s.count > 0 { // 本地存储的 初次解压的子文件MD5s
                    
                    let currentUnzipedFilesUrl = self.resourcesFileUrl.appendingPathComponent(resourceName)
                    if let currentUnzipedFilesMD5s = self.generateResourcesMD5s(inDirectory: currentUnzipedFilesUrl.path),
                        originalUpzipedFilesMD5s == currentUnzipedFilesMD5s { // 当前子文件的MD5s
                        
                        // Verify 2 result：当前zip包子文件的MD5 与 初次解压的zip包子文件的MD5 一致
                        return .verified
                    } else {
                        // Verify 2 result：当前zip包子文件的MD5 与 初次解压的zip包子文件的MD5 不一致，重新解压
                        return .needToUnzip
                    }
                } else {
                    // Verify 2 result：本地无初次解压zip子文件MD5，重新解压
                    return .needToUnzip
                }
            } else {
                // Verify 1 result：本地无zip包的MD5，或者与服务器MD5不一致，重新下载
                return .needToDownload
            }
        } else {
            // Verify result：本地无校验数据，说明是初次下载
            return .needToDownload
        }
    }
    
    // MARK: Download
    func downloadResource(_ resource: Resource) {
        
        guard let resourceName = resource.name else {
            return
        }
        guard let downloadUrl = resource.downloadUrl else {
            return
        }
        
        var storedResourceInfo = self.fetchStoredResourceInfoFromUserDefault(resourceName)
        let kZipFileMD5 = self.keyForZipFileMD5(resourceName: resourceName)
        
        self.loadDataFromURL(urlString: downloadUrl, success: { responseData in

            guard responseData != nil else {
                return
            }
            // 写入/解压 zip 包，写入前先删除原有zip包（如果存在）
            let zipUrlToWrited = self.resourcesFileUrl
                .appendingPathComponent("\(resourceName).zip", isDirectory: false)
            print("zipUrlToWrited :\(zipUrlToWrited.path)")
            // 不必删除原有文件，因为接下来的写入操作可以把原文件覆盖掉
            
            do {
                try (responseData as! Data).write(to: zipUrlToWrited, options: .atomic)
                
                // 先更新/存储 zip 包的 MD5
                let newServiceZipMD5 = (responseData as! Data).MD5
                storedResourceInfo?.updateValue(newServiceZipMD5, forKey: kZipFileMD5)
                UserDefaults.standard.setValue(storedResourceInfo, forKey: resourceName)
                UserDefaults.standard.synchronize()
                
                // 再解压
                let _ = self.unzipResource(resource)
                
            } catch {
                print("download resources failed. Error: \(error.localizedDescription))")
            }
            
        }, failure: { error in
            print(error!.localizedDescription)
        })
    }
    
    
    // MARK: unzip
    func unzipResource(_ resource: Resource) -> Bool {
        
        guard let resourceName = resource.name else {
            assertionFailure()
            return false
        }
        
        var storedResourceInfo = self.fetchStoredResourceInfoFromUserDefault(resourceName)
        let kUnzipedFilesMD5s = self.keyForUnzipedFilesMD5s(resourceName: resourceName)
        
        // 解压 zip 包，解压前先删除原有文件夹（如果存在）
        let storedZipUrl = self.resourcesFileUrl
            .appendingPathComponent("\(resourceName).zip", isDirectory: false)
        let zipUrlToUnzip = self.resourcesFileUrl.appendingPathComponent(resourceName, isDirectory: true)
        print("zipUrlToUnzip : \(zipUrlToUnzip.path)")
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: zipUrlToUnzip.path, isDirectory: &isDir) {
            try! FileManager.default.createDirectory(at: zipUrlToUnzip, withIntermediateDirectories: true, attributes: nil)
        }
        
        var error: NSError? = nil
        let result = SSZipArchive.unzipFile(atPath: storedZipUrl.path, toDestination: zipUrlToUnzip.path, preserveAttributes: true, overwrite: true, password: nil, error: &error, delegate: nil)
        if result == false {
            print("unzip resources failed. Error: \(String(describing: error?.localizedDescription))")
            return false
        }
        // 更新/存储 zip 包解压后所有文件的 MD5
        if let unzipedFilesMD5s = self.generateResourcesMD5s(inDirectory: zipUrlToUnzip.path) {
            print("unzipedFilesMD5s.count -> \(unzipedFilesMD5s.count)")
            storedResourceInfo?.updateValue(unzipedFilesMD5s, forKey: kUnzipedFilesMD5s)
            UserDefaults.standard.setValue(storedResourceInfo, forKey: resourceName)
            UserDefaults.standard.synchronize()
        }
        
        return true
    }
    
    // MARK: MD5
    func generateResourcesMD5s(inDirectory directoryPath: String) -> [String]? {
        let fileManager = FileManager.default
        var md5s = [String]()
        do {
            let subPaths = try fileManager.contentsOfDirectory(atPath: directoryPath)
            subPaths.forEach { subPath in
                
                let subAbsolutePath = directoryPath + "/" + subPath
                
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: subAbsolutePath, isDirectory: &isDir) {
                    if isDir.boolValue { // Dir
                        let subMD5s = self.generateResourcesMD5s(inDirectory: subAbsolutePath)
                        md5s.append(contentsOf: subMD5s!)
                    } else { // File
                        let fileData = try! Data(contentsOf: URL(fileURLWithPath: subAbsolutePath, isDirectory: true))
                        md5s.append(fileData.MD5)
                    }
                }
            }
            return md5s
        } catch {
            print("generateResourcesMD5s failed. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchStoredResourceInfoFromUserDefault(_ resourceName: String?, createInfoIfNotExist: Bool = true) -> [String: Any]? {
        guard resourceName != nil else {
            return nil
        }
        var storedResourceInfo = UserDefaults.standard.value(forKey: resourceName!) as? [String : Any]
        if storedResourceInfo == nil && createInfoIfNotExist == true {
            storedResourceInfo = [String: Any]()
        }
        return storedResourceInfo
    }
}

extension Data {
    var MD5: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = withUnsafeBytes { (bytes) in
            CC_MD5(bytes, CC_LONG(count), &digest)
        }
        var digestHex = ""
        for index in 0 ..< Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        return digestHex
    }
}
