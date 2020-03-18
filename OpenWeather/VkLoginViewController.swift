//
//  VkLoginViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import WebKit

class VkLoginViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "oauth.vk.com"
        components.path = "/authorize"
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: "7356728"),
            URLQueryItem(name: "display", value: "mobile"),
            URLQueryItem(name: "redirect_uri", value: "https://oauth.vk.com/blank.html"),
            URLQueryItem(name: "scope", value: "262150"),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "v", value: "5.68")
        ]
        
        
        let request = URLRequest(url: components.url!)
        webView.navigationDelegate = self
        webView.load(request)
    }
}

extension VkLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let url = navigationResponse.response.url, url.path == "/blank.html", let fragment = url.fragment else { 
            decisionHandler(.allow)
            return
        }
        
        
        let params = fragment
            .components(separatedBy: "&")
            .map { $0.components(separatedBy: "=" ) }
            .reduce([String: String]()) { (result, param) in
                var dict = result
                let key = param[0]
                let value = param[1]
                dict[key] = value
                return dict
        }
        
        let token = params["access_key"]
        print(token)
        decisionHandler(.cancel)
    }
}
