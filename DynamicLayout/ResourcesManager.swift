//
//  ResourcesManager.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/8.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit

@objc(PLResourcesManager)
public class ResourcesManager: NSObject {
    
    @objc(shareManager)
    public static let shared = ResourcesManager()
    
    public let handler = ResourcesHandler.shared
    
    required override init() {
        
    }
    
    @objc public func startFetchOrVerifyResources() {
        self.handler.loadHTMLSourcesFromService()
    }
    
    func fetchHtmlFile(filePath: String?) -> (String, URL)? {
        guard filePath != nil else {
            return nil
        }
            // 待优化
//        let components = filePath?.components(separatedBy: "?")
//        var paramsPath: String? = nil
//        if components!.count > 1 {
//            paramsPath = components![1]
//        }
//
//        var fileUrl = self.handler.resourcesFileUrl.appendingPathComponent(components!.first!)
//
//        if paramsPath != nil {
//            let fileUrlWithParams = URL(fileURLWithPath: fileUrl.path + paramsPath!)
//            fileUrl = fileUrlWithParams
//        }
        
        // FIXME: 拼接 url 的做法不优雅
        if let fileUrl = URL(string: self.handler.resourcesFileUrl.absoluteString + filePath!),
            let htmlString = try? String(contentsOf: fileUrl, encoding: .utf8) {
            return (htmlString, fileUrl)
        }
        return nil
    }
    
}
