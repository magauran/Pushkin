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

protocol ChatMessage {}

struct PlainTextMessage: ChatMessage {
    let text: String
}

struct ImageMessage: ChatMessage {
    let imageURL: String
}

struct SoundMessage: ChatMessage {
    let audioURL: String
}

struct CoordsMessage: ChatMessage {
    let latitude: Double
    let longitude: Double
}

struct ChatResponse: Decodable {
    let image_url: String?
    let coords: String?
    let response: String?
}

extension ChatResponse {
    func mapToChatMessages() -> [ChatMessage] {
        var result: [ChatMessage] = []

        if let text = response {
            result.append(PlainTextMessage(text: text))
        }

        if let imageURL = image_url {
            result.append(ImageMessage(imageURL: imageURL))
        }

        if let coordsString = coords {
            let coordsArray = coordsString.split(separator: ",").compactMap({ Double($0) })
            if coordsArray.count == 2, let latitude = coordsArray.first, let longitude = coordsArray.last {
                result.append(CoordsMessage(latitude: latitude, longitude: longitude))
            }
        }
        return result
    }
}

extension Data {
    func parseToChatResponses() -> [ChatResponse] {
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode([ChatResponse].self, from: self)
            return result
        } catch {
            print(error)
            return []
        }
    }
}

extension Array where Element == ChatResponse {
    func mapToChatMessages() -> [ChatMessage] {
        return self.flatMap { $0.mapToChatMessages() }
    }
}

typealias Answer = [ChatMessage]
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
                handler(.success([]))
            }
            return
        }
    }
}

final class ChatServiceImpl: NSObject, URLSessionDelegate, ChatService {
    static private let urlString = "https://c278d005.ngrok.io"

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
                let answer = data.parseToChatResponses().mapToChatMessages()
                if answer.isEmpty {
                    handler(.failure(.unknown))
                } else {
                    handler(.success(answer))
                }
            } else {
                print("Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
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
