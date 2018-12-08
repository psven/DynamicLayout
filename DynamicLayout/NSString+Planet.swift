//
//  NSString+Planet.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/8.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit

@objc
enum PlanetTemplateMessageType: NSInteger {
    case unknown = 0
    case location = 1
    case template = 2
    
}

@objc
extension NSString {
    
    var jsonDictionaryIfExist: [String: Any]? {
        let data = self.data(using: String.Encoding.utf8.rawValue)
        return try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! Dictionary<String, Any>
    }
    
    var planetTemplateMessageType: PlanetTemplateMessageType {
        if let dict = self.jsonDictionaryIfExist, dict["type"] != nil {
            let typeString = dict["type"] as! String
            switch typeString {
            case "location": return .location
            case "template": return .template
            default: return .unknown
            }
        }
        return .unknown
    }
    
    
    
    var locationFormatedString: String? {
        if self.planetTemplateMessageType == .location {
            var formatedString: String = ""
            let locationName = self.jsonDictionaryIfExist!["name"] as! String
            let locationDetail = self.jsonDictionaryIfExist!["address"] as! String
            if locationName.count > 0 {
                formatedString = formatedString + "\(locationName)\n\(locationDetail)"
            } else {
                formatedString = locationDetail
            }
            return formatedString
        }
        return nil
    }
    
    var locationCoordinateIfExist: [String: NSNumber]? {
        if self.planetTemplateMessageType == .location {
            var coordinateIfExist: [String: NSNumber] = [:]
            let latitude = self.jsonDictionaryIfExist!["latitude"] as! NSNumber
            let longitude = self.jsonDictionaryIfExist!["longitude"] as! NSNumber
            coordinateIfExist.updateValue(latitude, forKey: "latitude")
            coordinateIfExist.updateValue(longitude, forKey: "longitude")
            return coordinateIfExist
        }
        return nil
    }
    
}
