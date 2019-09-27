//
//  ChatViewController.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/27/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit
import class CoreLocation.CLLocation

struct Sender: SenderType {
    let senderId = UUID().uuidString
    let displayName: String

    init(displayName: String) {
        self.displayName = displayName
    }

}

struct Message: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}

struct LocationMessage: LocationItem {
    let location: CLLocation
    let size = CGSize(width: 270, height: 100)
}

final class ChatViewController: MessagesViewController {
    private let user = Sender(displayName: "Вы")
    private let bot = Sender(displayName: "Помощник")

    private lazy var messages = [
        Message(sender: self.user, messageId: "1", sentDate: Date().addingTimeInterval(-143), kind: .text("Привет")),
        Message(sender: self.bot, messageId: "2", sentDate: Date().addingTimeInterval(-54), kind: .text("Как дела?")),
        Message(sender: self.user, messageId: "3", sentDate: Date().addingTimeInterval(-32), kind: .text("Норм")),
        Message(sender: self.bot, messageId: "4", sentDate: Date().addingTimeInterval(-14), kind: .text("А у тебя?")),
        Message(sender: self.user, messageId: "5", sentDate: Date().addingTimeInterval(-11), kind: .text("Тоже")),
        Message(sender: self.user, messageId: "6", sentDate: Date().addingTimeInterval(-10), kind: .text("Ты где?")),
        Message(sender: self.bot, messageId: "7", sentDate: Date().addingTimeInterval(-8), kind: .text("Санкт-Петербург, Исакиевская площадь, д. 1")),
        Message(sender: self.bot, messageId: "8", sentDate: Date().addingTimeInterval(-7), kind: .location(LocationMessage(location: CLLocation(latitude: 59.9338, longitude: 30.3030)))),
        Message(sender: self.user, messageId: "9", sentDate: Date().addingTimeInterval(-5), kind: .text("Сейчас подъеду")),
        Message(sender: self.bot, messageId: "10", sentDate: Date().addingTimeInterval(-1), kind: .text("На всякий случай вот мой номер: 88005553535"))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self

        self.setupMessageInputBar()
    }

    private func setupMessageInputBar() {
        
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return self.user
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return self.messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return self.messages.count
    }


}

extension ChatViewController: MessagesLayoutDelegate {

}

extension ChatViewController: MessagesDisplayDelegate {
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.address, .date, .phoneNumber, .url]
    }
}
