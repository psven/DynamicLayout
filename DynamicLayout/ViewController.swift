//
//  ViewController.swift
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/6.
//  Copyright © 2018 LyinTech. All rights reserved.
//

import UIKit
import WebKit

class MessageHandler: NSObject, WKScriptMessageHandler {
    
    // 代理转发，避免内存泄露
    weak var forwardDelegate: WKScriptMessageHandler?
    
    required init(forwardDelegate: WKScriptMessageHandler?) {
        self.forwardDelegate = forwardDelegate
    }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        self.forwardDelegate?.userContentController(userContentController, didReceive: message)
    }
}

class ViewController: UIViewController, TemplateElementDelegate {

    var templateElement: TemplateElement?
    var webView: WKWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        ResourcesManager.shared.startFetchOrVerifyResources()
        
        self.mockReciveTemplateMessage()
        
        configureWebView()
        
    }
    
    
    func configureWebView() {
        // create webview
        let scriptMessageHandler = MessageHandler(forwardDelegate: self)
        
        let userContentController = WKUserContentController()
        userContentController.add(scriptMessageHandler, name: "connectWallet")
        userContentController.add(scriptMessageHandler, name: "getConnectWeb3jUrl")
        userContentController.add(scriptMessageHandler, name: "web3jsendTransactionDevelop")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false 
        self.webView = webView
    }
    
    func elementDidClicked(element: TemplateElement, model: TemplateModel) {
        
        if let (htmlString, fileUrl) = ResourcesManager.shared.fetchHtmlFile(filePath: model.target.url) {
            
            self.view.addSubview(webView)
            if model.target.evenlopeViewSize == .zero {
                webView.autoPinEdgesToSuperviewEdges()
            } else {
                webView.autoCenterInSuperview()
                webView.autoSetDimensions(to: model.target.evenlopeViewSize)
            }
            webView.loadHTMLString(htmlString, baseURL: fileUrl)
        }
    }

    

    @objc func mockReciveTemplateMessage() {
        
        let path = Bundle.main.path(forResource: "发送未领取", ofType: "json")
        let json = try! String.init(contentsOf: URL(fileURLWithPath: path!))
        
        let model = TemplateModel.deserialize(from: json)
        self.templateElement = TemplateElement.init(withTemplateModel: model!, superView: self.view)
        self.templateElement!.delegate = self
        
    }

}

extension ViewController: WKNavigationDelegate , WKScriptMessageHandler {
    
    // js call Swift
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        print(message.name)
        switch message.name {
        case "connectWallet": break
        case "getConnectWeb3jUrl": break
        case "web3jsendTransactionDevelop": break
            
        default: break
            
        }
    }
    
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("")
    }
}
