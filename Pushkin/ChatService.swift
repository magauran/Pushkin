//
//  ChatService.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import UIKit

class ChatService: NSObject, URLSessionDelegate {
    typealias Answer = String
    typealias AnswerHandler = (Answer?) -> Void
    static private let urlString = "https://"

    lazy private var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }()

    func send(question: String, completionHandler: @escaping AnswerHandler) {
        guard let serviceUrl = URL(string: "\(ChatService.urlString)/message") else {
            completionHandler(nil)
            return
        }
        let parameterDictionary = ["request" : question,
                                   "id" : UIDevice.current.identifierForVendor!.uuidString]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            completionHandler(nil)
            return
        }
        request.httpBody = httpBody

        session.dataTask(with: request) { (data, response, error) in
            if let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 {
                let answer = String(data: data, encoding: String.Encoding.utf8)
                completionHandler(answer)
            }
        }.resume()
    }

    // MARK: - URL Session delegate
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?
    ) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let cred = challenge.protectionSpace.serverTrust.map { URLCredential(trust: $0) }
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, cred)
        }
    }
}
