//
//  ChatViewController.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/27/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit
import class CoreLocation.CLLocation
import SnapKit
import Closures
import InputBarAccessoryView
import Repeat
import Keyboardy

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

    private lazy var menuStackView: UIStackView = {
        let cameraButton = UIButton()
        cameraButton.setImage(UIImage(named: "camera"), for: .normal)
        cameraButton.onTap { [weak self] in
            self?.configureMessageInputBarForPhoto()
        }

        let keyboardButton = UIButton()
        keyboardButton.setImage(UIImage(named: "keyboard"), for: .normal)
        keyboardButton.onTap { [weak self] in
            self?.configureMessageInputBarForKeyboard()
        }

        let microphoneButton = UIButton()
        microphoneButton.setImage(UIImage(named: "microphone"), for: .normal)
        microphoneButton.onTap { [weak self] in
            self?.configureMessageInputBarForSpeech()
        }

        let buttons = [keyboardButton, microphoneButton, cameraButton]

        buttons.forEach { button in
            button.imageView?.contentMode = .scaleAspectFit
        }

        let spaces = [UIView(), UIView()]
        spaces.forEach {
            $0.snp.makeConstraints { make in
                make.width.equalTo(40)
            }
        }

        let stackView = UIStackView(arrangedSubviews: [spaces[0]] + buttons + [spaces[1]])
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.snp.makeConstraints { make in
            make.height.equalTo(38)
        }

        return stackView
    }()

    lazy var debouncer = Debouncer(.seconds(1)) {
        DispatchQueue.main.async { [weak self] in
            self?.configureMessageInputBarForMenu()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self

        self.configureMessageInputBarForMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.unregisterFromKeyboardNotifications()
    }

    private func configureMessageInputBarForMenu() {
        self.messageInputBar.setMiddleContentView(self.menuStackView, animated: false)
        self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
    }

    private func configureMessageInputBarForKeyboard() {
        self.messageInputBar.setMiddleContentView(self.messageInputBar.inputTextView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 52, animated: true)
    }

    private func configureMessageInputBarForSpeech() {
       
    }

    private func configureMessageInputBarForPhoto() {

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

extension ChatViewController: KeyboardStateDelegate {
    func keyboardWillTransition(_ state: KeyboardState) {}

    func keyboardTransitionAnimation(_ state: KeyboardState) {}

    func keyboardDidTransition(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight(_):
            ()
        case .hidden:
            self.debouncer.call()
        }
    }
}
