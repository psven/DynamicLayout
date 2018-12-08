//
//  RedEnvelopeLayoutManager.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/6.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit
import PureLayout

class BackgroundView: UIButton {
    
    var normalColor: UIColor?
    var selectedColor: UIColor?
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? selectedColor : normalColor
        }
    }
    required init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChildBackgroundView: UIImageView {
    
    var normalColor: UIColor?
    var selectedColor: UIColor?
    var normalImage: UIImage?
    var selectedImage: UIImage?
    var isSelected: Bool = false {
        didSet {
            self.image = isSelected ? selectedImage : normalImage
            self.backgroundColor = isSelected ? selectedColor : normalColor
        }
    }
    required init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objc(PLTemplateElementDelegate)
protocol TemplateElementDelegate {
    func elementDidClicked(element: TemplateElement, model: TemplateModel)
}

@objc(PLTemplateElement)
public class TemplateElement: UIView {
    
    weak var delegate: TemplateElementDelegate?
    var model: TemplateModel
    
    var isSelected: Bool! = false {
        didSet {
            self.subviews.forEach { subview in
                if subview.isKind(of: BackgroundView.self) {
                    (subview as! BackgroundView).isSelected = isSelected
                } else if subview.isKind(of: ChildBackgroundView.self) {
                    (subview as! ChildBackgroundView).isSelected = isSelected
                }
            }
        }
    }
    
    required public init(withTemplateModel model: TemplateModel, superView: UIView!) {
        
        self.model = model
        
        super.init(frame: .zero)
        
        // 后续消息cell如果需要响应手势则考虑将background手势去掉
//        let tapGes = UITapGestureRecognizer(target: self, action: #selector(handleClickEvent))
//        self.addGestureRecognizer(tapGes)
        
        let screenWidth = UIScreen.main.bounds.size.width
        let factor = screenWidth / model.basewidth
        superView.addSubview(self)
        
        // 同步 target view 的尺寸
        if var targetElementWidth = self.model.target.width, targetElementWidth > 0,
            var targetElementHeight = self.model.target.height, targetElementHeight > 0 {
            targetElementWidth *= factor
            targetElementHeight *= factor
            self.model.target.width = targetElementWidth
            self.model.target.height = targetElementHeight
        }
        
        // basic
        let width = model.width! * factor
        let height = model.height! * factor
        if width > 0 && height > 0 {
            self.autoAlignAxis(toSuperviewAxis: .horizontal)
            self.autoAlignAxis(toSuperviewAxis: .vertical)
            self.autoSetDimensions(to: CGSize(width: width, height: height))
        } else {
            self.autoPinEdgesToSuperviewEdges()
        }
        
        // state background view
        if let attributes = model.background {
            
            let background = BackgroundView()
//            background.isUserInteractionEnabled = false // 后续消息cell如果需要响应手势则考虑将background手势去掉
            background.addTarget(self, action: #selector(handleClickEvent), for: .touchUpInside)
            self.addSubview(background)
            background.autoPinEdgesToSuperviewEdges()
            
            if var radius = attributes.radius {
                radius *= factor
                background.layer.cornerRadius = radius
                background.clipsToBounds = true
            }
            if let normalColor = attributes.color {
                background.normalColor = normalColor
            }
            if let selectedColor = attributes.pressed_color {
                background.selectedColor = selectedColor
            }
            if let normalImageName = attributes.src, let image = UIImage(named: normalImageName) {
                background.setBackgroundImage(image, for: .normal)
            }
            if let selectedImageName = attributes.pressed_src, let image = UIImage(named: selectedImageName) {
                background.setBackgroundImage(image, for: .highlighted)
            }
            background.isSelected = false
        }
        
        // childs
        model.childs?.forEach({ child in
            
            var element: UIView? = nil
            
            if let imagePath = child.src {
                element = UIImageView()
                (element as! UIImageView).image = UIImage(named: imagePath)
            }
            
            if let text = child.text {
                element = UILabel()
                (element as! UILabel).text = text
                (element as! UILabel).font = UIFont.systemFont(ofSize: 14)
                
                if let textColor = child.color {
                    (element as! UILabel).textColor = textColor
                }
                
                let fontSize = child.fontSize! * factor
                if fontSize > 0 {
                    (element as! UILabel).font = UIFont.systemFont(ofSize: fontSize)
                }
                if let bold = child.Bold, bold == true {
                    (element as! UILabel).font = UIFont.boldSystemFont(ofSize: fontSize)
                }
            }
            self.addSubview(element!)
            
            if var left = child.left {
                left *= factor
                element!.autoPinEdge(toSuperviewEdge: .left, withInset: left)
            }
            if var right = child.right {
                right *= factor
                element!.autoPinEdge(toSuperviewEdge: .right, withInset: right)
            }
            if var top = child.top {
                top *= factor
                element!.autoPinEdge(toSuperviewEdge: .top, withInset: top)
            }
            if var bottom = child.bottom {
                bottom *= factor
                element!.autoPinEdge(toSuperviewEdge: .bottom, withInset: bottom)
            }
            if var width = child.width {
                width *= factor
                element!.autoSetDimension(.width, toSize: width)
            }
            if var height = child.height {
                height *= factor
                element!.autoSetDimension(.height, toSize: height)
            } 
            
            // state background view
            if let attributes = child.background {
                
                let background = ChildBackgroundView()
                self.insertSubview(background, belowSubview: element!)
                background.autoPinEdge(.left, to: .left, of: element!)
                background.autoPinEdge(.top, to: .top, of: element!)
                background.autoPinEdge(.right, to: .right, of: element!)
                background.autoPinEdge(.bottom, to: .bottom, of: element!)
                
                if var radius = attributes.radius {
                    radius *= factor
                    background.layer.cornerRadius = radius
                    background.clipsToBounds = true
                }
                if let normalColor = attributes.color {
                    background.normalColor = normalColor
                }
                if let selectedColor = attributes.pressed_color {
                    background.selectedColor = selectedColor
                }
                if let normalImageName = attributes.src, let image = UIImage(named: normalImageName) {
                    background.normalImage = image
                }
                if let selectedImageName = attributes.pressed_src, let image = UIImage(named: selectedImageName) {
                    background.selectedImage = image
                }
                background.isSelected = false
            }
        })
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleClickEvent() {
        self.delegate?.elementDidClicked(element: self, model: self.model)
    }
    
}
