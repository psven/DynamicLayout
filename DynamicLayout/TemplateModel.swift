//
//  RedEnvelopeModel.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/6.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit 
import HandyJSON


@objc
public class TemplateModel: NSObject, HandyJSON {
    
    var type: MessageType!
    var title: String?
    var id: String?
    var target: TempalteTarget!
    
    var basewidth: CGFloat!
    var width: CGFloat?
    var height: CGFloat?
    var background: BackgroundAttribute?
    
    var childs: [Child]?
    
    public func mapping(mapper: HelpingMapper) {
        mapper.specify(property: &childs, name: "child")
    }
    
    required public override init() {}
}


class TempalteTarget: HandyJSON {
    var url: String!
    var width: CGFloat?
    var height: CGFloat?
    var evenlopeViewSize: CGSize {
        if let width = self.width, let height = self.height {
            return CGSize(width: width, height: height)
        }
        return .zero
    }
    
    required init() {}
}

class BackgroundAttribute: HandyJSON {
    var src: String?
    var pressed_src: String?
    var radius: CGFloat?
    var color: UIColor?
    var pressed_color: UIColor?
     
    func mapping(mapper: HelpingMapper) {
        
        mapper.specify(property: &color) { (rawString) -> UIColor? in
            if let color = UIColor(hexString: rawString) {
                return color
            }
            return nil
        }
        mapper.specify(property: &pressed_color) { (rawString) -> UIColor? in
            if let color = UIColor(hexString: rawString) {
                return color
            }
            return nil
        }
    }
    
    required init() {}
}

enum MessageType: String, HandyJSONEnum {
    case template = "template"
    case location = "location"
}

class Child: HandyJSON {
    
    var left: CGFloat? // 左间距
    var right: CGFloat? // 右间距
    var top: CGFloat? // 顶部间距
    var bottom: CGFloat? // 底部间距
    
    var src: String? // 有值说明是图片类型
    var text: String? // 有值说明是文本类型
    var width: CGFloat? // 图片宽度
    var height: CGFloat? // 图片高度
    var fontSize: CGFloat? // 字体大小
    var color: UIColor? // 字体颜色
    var Bold: Bool? // 加粗
    
    var background: BackgroundAttribute?
    
    func mapping(mapper: HelpingMapper) {
        
        mapper.specify(property: &fontSize, name: "size")
        
        mapper.specify(property: &color) { (rawString) -> UIColor? in
            if let color = UIColor(hexString: rawString) {
                return color
            }
            return nil
        }
    }
    
    required init() {}
}


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])
        let red, green, blue, alpha: CGFloat
        switch chars.count {
        case 3:
            chars = chars.flatMap { [$0, $0] }
            fallthrough
        case 6:
            chars = ["F","F"] + chars
            fallthrough
        case 8:
            alpha = CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255
            red   = CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255
            green = CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255
            blue  = CGFloat(strtoul(String(chars[6...7]), nil, 16)) / 255
        default:
            return nil
        }
        self.init(red: red, green: green, blue:  blue, alpha: alpha)
    }
}
