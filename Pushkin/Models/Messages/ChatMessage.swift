//
//  ChatMessage.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

protocol ChatMessage {
    var speechText: String? { get }
}

extension ChatMessage {
    var speechText: String? {
        return nil
    }
}

struct PlainTextMessage: ChatMessage {
    let text: String
    let speechText: String?
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

struct ButtonsMessage: ChatMessage {
    let models: [ActionButtonModel]
}

extension ChatMessage {
    func mapToMessageKind() -> MessageKind? {
        switch self {
        case let plainTextMessage as PlainTextMessage:
            let trimmingText = plainTextMessage.text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .text(trimmingText)
        case let coordsMessage as CoordsMessage:
            return .location(Location(location: CLLocation(latitude: coordsMessage.latitude, longitude: coordsMessage.longitude)))
        case let audioMessage as SoundMessage:
            if let url = URL(string: audioMessage.audioURL) {
                return .audio(Audio(url: url))
            } else {
                return nil
            }
        case let imageMessage as ImageMessage:
            if let url = URL(string: imageMessage.imageURL) {
                return .photo(Media(url: url))
            } else {
                return nil
            }
        case let buttonsMessage as ButtonsMessage:
            let models = buttonsMessage.models
            return .custom(models)
        default:
            assertionFailure()
            return .text("")
        }
    }
}

extension Array where Element == ChatMessage {
    func mapToMessageKinds() -> [MessageKind] {
        return self.compactMap { $0.mapToMessageKind() }
    }
}
