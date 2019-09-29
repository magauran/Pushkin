//
//  ChatResponse.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation

struct ChatResponse: Decodable {
    let image_url: String?
    let coords: String?
    let response: String?
    let audio_url: String?
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

        if let audioURL = audio_url {
            result.append(SoundMessage(audioURL: audioURL))
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
