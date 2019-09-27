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
    private let isFailure = false

    func send(message: String, then handler: @escaping AnswerHandler) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            if self.isFailure {
                handler(.failure(.unknown))
            } else {
                handler(.success("Hello!"))
            }
            return
        }
    }
}

final class ChatServiceImpl: NSObject, URLSessionDelegate, ChatService {
    static private let urlString = "http://95.213.38.6:1488"

    lazy private var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }()

    func send(message: String, then handler: @escaping AnswerHandler) {
        var components = URLComponents(string: "\(ChatServiceImpl.urlString)/text")
        components?.queryItems = [URLQueryItem(name: "text", value: message)]

        guard let serviceUrl = components?.url else {
            handler(.failure(.unknown))
            return
        }

        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"

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
