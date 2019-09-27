//
//  ChatService.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import UIKit

enum ChatError: Error {
    case unknown
}

typealias Answer = String
typealias AnswerHandler = (Result<Answer, ChatError>) -> Void

protocol ChatService: AnyObject {
    func send(message: String, then handler: @escaping AnswerHandler)
}

final class MockChatService: ChatService {
    func send(message: String, then handler: @escaping AnswerHandler) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            handler(.success("Hello!"))
            return
        }
    }
}

final class ChatServiceImpl: NSObject, URLSessionDelegate, ChatService {
    static private let urlString = "http://5a17efef.ngrok.io/"

    lazy private var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }()

    func send(message: String, then handler: @escaping AnswerHandler) {
        guard let serviceUrl = URL(string: "\(ChatServiceImpl.urlString)/text") else {
            handler(.failure(.unknown))
            return
        }
        let parameterDictionary = ["text" : message]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            handler(.failure(.unknown))
            return
        }
        request.httpBody = httpBody

        session.dataTask(with: request) { (data, response, error) in
            if let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 {
                let answer = String(decoding: data, as: UTF8.self)
                handler(.success(answer))
            } else {
                handler(.failure(.unknown))
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
