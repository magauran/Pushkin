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

    init(sender: SenderType, kind: MessageKind) {
        self.sender = sender
        self.messageId = UUID().uuidString
        self.sentDate = Date()
        self.kind = kind
    }
}

struct LocationMessage: LocationItem {
    let location: CLLocation
    let size = CGSize(width: 270, height: 100)
}

final class ChatViewController: MessagesViewController {
    private let chatService: ChatService = ChatServiceImpl()
    private let user = Sender(displayName: "Вы")
    private let bot = Sender(displayName: "Помощник")

    private var messages = [Message]()

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

        self.fillMessages()

        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self

        self.configureMessageInputBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.unregisterFromKeyboardNotifications()
    }

    private func fillMessages() {
        self.messages = [
            Message(sender: self.user, kind: .text("Привет")),
            Message(sender: self.bot, kind: .text("Как дела?")),
            Message(sender: self.user, kind: .text("Норм")),
            Message(sender: self.bot, kind: .text("А у тебя?")),
            Message(sender: self.user, kind: .text("Тоже")),
            Message(sender: self.user, kind: .text("Ты где?")),
            Message(sender: self.bot, kind: .text("Санкт-Петербург, Исакиевская площадь, д. 1")),
            Message(sender: self.bot, kind: .location(LocationMessage(location: CLLocation(latitude: 59.9338, longitude: 30.3030)))),
            Message(sender: self.user, kind: .text("Сейчас подъеду")),
            Message(sender: self.bot, kind: .text("На всякий случай вот мой номер: 88005553535"))
        ]
    }

    private func configureMessageInputBar() {
        self.configureMessageInputBarForMenu()
        self.messageInputBar.delegate = self
    }

    private func configureMessageInputBarForMenu() {
        self.messageInputBar.setMiddleContentView(self.menuStackView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)
    }

    private func configureMessageInputBarForKeyboard() {
        self.messageInputBar.setMiddleContentView(self.messageInputBar.inputTextView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 52, animated: true)
        self.messageInputBar.setStackViewItems([], forStack: .bottom, animated: true)
        self.messageInputBar.inputTextView.becomeFirstResponder()
        self.messagesCollectionView.scrollToBottom(animated: true)
    }

    private func configureMessageInputBarForSpeech() {
        let speechView = SpeechView()
        speechView.snp.makeConstraints { make in
            make.height.equalTo(150)
        }
        speechView.addTapGesture { [weak self] _ in
            self?.configureMessageInputBarForMenu()
        }

        self.messageInputBar.setMiddleContentView(speechView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)
    }

    private func configureMessageInputBarForPhoto() {

    }

    private func sendMessage(_ message: Message) {
        guard case let .text(text) = message.kind else { return assertionFailure() }

        self.insertMessage(message)
        self.setTypingIndicatorViewHidden(false, animated: true)
        self.chatService.send(message: text) { [weak self] result in
            guard let self = self else { return assertionFailure() }
            let answerMessage: Message
            switch result {
            case .success(let answer):
                answerMessage = Message(sender: self.bot, kind: .text(answer))
            case .failure(let error):
                print(error)
                answerMessage = Message(sender: self.bot, kind: .text("Извини, сервак упал :с"))
            }

            DispatchQueue.main.async {
                self.setTypingIndicatorViewHidden(
                    true,
                    animated: true,
                    whilePerforming: { [weak self] in
                        self?.insertMessage(answerMessage)
                    },
                    completion: { [weak self] success in
                        if success, self?.isLastSectionVisible() == true {
                            self?.messagesCollectionView.scrollToBottom(animated: true)
                        }
                    }
                )
            }
        }
    }

    private func insertMessage(_ message: Message) {
        self.messages.append(message)
        self.messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([self.messages.count - 1])
            if self.messages.count >= 2 {
                self.messagesCollectionView.reloadSections([self.messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }

    private func isLastSectionVisible() -> Bool {
        guard !self.messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: self.messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
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

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        let message = Message(sender: self.user, kind: .text(text))
        self.sendMessage(message)
        self.messagesCollectionView.scrollToBottom(animated: true)
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
