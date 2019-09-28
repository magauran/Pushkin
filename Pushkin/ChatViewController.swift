//
//  ChatViewController.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/27/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit
import class CoreLocation.CLLocation
import MapKit
import SnapKit
import Closures
import InputBarAccessoryView
import Repeat
import Keyboardy
import AVFoundation

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
    var kind: MessageKind

    init(sender: SenderType, kind: MessageKind) {
        self.sender = sender
        self.messageId = UUID().uuidString
        self.sentDate = Date()
        self.kind = kind
    }
}

struct Audio: AudioItem {
    let url: URL
    let size: CGSize
    let duration: Float

    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 200, height: 40)
        let audioAsset = AVURLAsset(url: url)
        self.duration = Float(CMTimeGetSeconds(audioAsset.duration))
    }
}

enum MessangerState {
    case menu
    case speech
    case keyboard
    case photo
}

struct LocationMessage: LocationItem {
    let location: CLLocation
    let size = CGSize(width: 270, height: 100)
}

final class ChatViewController: MessagesViewController {
    private let chatService: ChatService = ChatServiceImpl()
    private let speechRecognizer = SpeechRecognizer()
    private let speaker = Speaker()
    private let calendarManager = CalendarManager()
    private lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    private let user = Sender(displayName: "Вы")
    private let bot = Sender(displayName: "Арина")
    private let system = Sender(displayName: "Система")

    private(set) var messages = [Message]()
    private var state: MessangerState = .menu
    private var needInitialScrolling = false
    private var hasUnsentMessage = false

    private lazy var menuStackView: UIStackView = {
        let cameraButton = UIButton()
        cameraButton.setImage(UIImage(named: "camera"), for: .normal)
        cameraButton.onTap { [weak self] in
            self?.state = .photo
            self?.configureMessageInputBarForPhoto()
        }

        let keyboardButton = UIButton()
        keyboardButton.setImage(UIImage(named: "keyboard"), for: .normal)
        keyboardButton.onTap { [weak self] in
            self?.state = .keyboard
            self?.configureMessageInputBarForKeyboard()
        }

        let microphoneButton = UIButton()
        microphoneButton.setImage(UIImage(named: "microphone"), for: .normal)
        microphoneButton.onTap { [weak self] in
            self?.state = .speech
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

    lazy var debouncer = Debouncer(.seconds(0.2)) {
        DispatchQueue.main.async { [weak self] in
            self?.configureMessageInputBarForMenu()
        }
    }

    override func viewDidLoad() {
        self.messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: ActionButtonsMessagesFlowLayout())
        self.messagesCollectionView.register(ActionButtonsMessageCell.self)

        super.viewDidLoad()


        self.fillMessages()

        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self
        self.messagesCollectionView.messageCellDelegate = self

        self.configureMessageInputBar()

        let layout = self.messagesCollectionView.messagesCollectionViewFlowLayout
        layout.setMessageIncomingAvatarSize(.init(width: 40, height: 40))
        layout.setMessageOutgoingAvatarSize(.zero)
        layout.setMessageIncomingMessageTopLabelAlignment(
            LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0))
        )
        self.messagesCollectionView.contentInset.top = 20
        self.additionalBottomInset = 20
        self.messagesCollectionView.showsVerticalScrollIndicator = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.registerForKeyboardNotifications(self)
        self.messagesCollectionView.scrollToBottom(animated: true)
        self.needInitialScrolling = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.unregisterFromKeyboardNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.audioController.stopAnyOngoingPlaying()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.needInitialScrolling {
            self.messagesCollectionView.scrollToBottom(animated: true)
            self.needInitialScrolling.toggle()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard messages.indices.contains(indexPath.section) else { return super.collectionView(collectionView, cellForItemAt: indexPath) }
        let message = self.messageForItem(at: indexPath, in: self.messagesCollectionView)
        if case .custom = message.kind {
            let cell = self.messagesCollectionView.dequeueReusableCell(ActionButtonsMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: self.messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }

    private func fillMessages() {
        let buttonModels = [
            ActionButtonModel(displayTitle: "Кнопка1", action: "action1"),
            ActionButtonModel(displayTitle: "Кнопка2", action: "action2"),
            ActionButtonModel(displayTitle: "Кнопка3", action: "action3")
        ]
        let yetAnotherMessage = Message(sender: self.bot, kind: .custom(buttonModels))

        self.messages = [
            Message(sender: self.user, kind: .text("Привет")),
            Message(sender: self.bot, kind: .text("Как дела?")),
            Message(sender: self.user, kind: .text("Норм")),
            Message(sender: self.bot, kind: .text("А у тебя?")),
            Message(sender: self.user, kind: .text("Тоже")),
            Message(sender: self.system, kind: .text("Ты где?")),
            Message(sender: self.bot, kind: .text("Санкт-Петербург, Исакиевская площадь, д. 1")),
            Message(sender: self.bot, kind: .location(LocationMessage(location: CLLocation(latitude: 59.9338, longitude: 30.3030)))),
            Message(sender: self.user, kind: .text("Я подъеду завтра в 10 утра")),
            Message(sender: self.bot, kind: .text("На всякий случай вот мой номер: 88005553535")),
            Message(sender: self.system, kind: .audio(Audio(url: URL(string: "https://media.izi.travel/fae0d384-5475-4134-a0bf-eab6bbf42a1b/8456eea1-fbbd-4f1e-a1bc-80862ea23dd2.m4a")!))),
            yetAnotherMessage, yetAnotherMessage
        ]
    }

    private func configureMessageInputBar() {
        self.configureMessageInputBarForMenu()
        self.messageInputBar.delegate = self
    }

    private func configureMessageInputBarForMenu() {
        self.messageInputBar.setMiddleContentView(self.menuStackView, animated: false)
        self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)
        self.messagesCollectionView.scrollToBottom(animated: true)
    }

    private func configureMessageInputBarForKeyboard() {
        self.messageInputBar.setMiddleContentView(self.messageInputBar.inputTextView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 52, animated: true)
        self.messageInputBar.setStackViewItems([], forStack: .bottom, animated: true)
        self.messageInputBar.inputTextView.becomeFirstResponder()
        self.messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 8)
        self.messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 8)
    }

    private func configureMessageInputBarForSpeech() {
        let speechView = SpeechView()
        speechView.snp.makeConstraints { make in
            make.height.equalTo(150)
        }

        var recordFinished = false

        speechView.addTapGesture { [weak self] _ in
            guard let self = self else { return }
            recordFinished = true
            self.speechRecognizer.stopRecording()
            if self.hasUnsentMessage {
                self.sendMessage(self.messages[self.messages.count - 1], needInsert: false)
                self.hasUnsentMessage.toggle()
            }
            self.state = .menu
            self.configureMessageInputBarForMenu()
        }

        self.messageInputBar.setMiddleContentView(speechView, animated: true)
        self.messageInputBar.setRightStackViewWidthConstant(to: 0, animated: true)

        var newMessageId: String? = nil
        self.speechRecognizer.startRecording { [weak self] question in
            guard let self = self else { return }
            guard !recordFinished else { return }
            if self.messages.last?.messageId == .some(newMessageId) {
                self.messages[self.messages.count - 1].kind = .text(question)
                self.messagesCollectionView.performBatchUpdates({
                    self.messagesCollectionView.reloadSections([self.messages.count - 1])
                })
            } else {
                let newMessage = Message(sender: self.user, kind: .text(question))
                newMessageId = newMessage.messageId
                self.insertMessage(newMessage)
                self.hasUnsentMessage = true
            }
        }
    }

    private func configureMessageInputBarForPhoto() {

    }

    private func sendMessage(_ message: Message, needInsert: Bool = true) {
        guard case let .text(text) = message.kind else { return assertionFailure() }

        if needInsert {
            self.insertMessage(message)
        }

        self.setTypingIndicatorViewHidden(false, animated: true)
        self.chatService.send(message: text) { [weak self] result in
            guard let self = self else { return assertionFailure() }
            let answerMessages: [Message]
            let speakText: String?

            switch result {
            case .success(let answer):
                let messageKinds = answer.mapToMessageKinds()
                answerMessages = messageKinds.map { Message(sender: self.bot, kind: $0) }
                speakText = answer.compactMap { $0.speechText }.joined(separator: ". ")
            case .failure(let error):
                print(error)
                answerMessages = [Message(sender: self.system, kind: .text("Извини, сервак упал :с"))]
                speakText = nil
            }

            DispatchQueue.main.async {
                self.setTypingIndicatorViewHidden(
                    true,
                    animated: true,
                    whilePerforming: { [weak self] in
                        self?.insertMessages(answerMessages)
                        speakText.map {
                            self?.speaker.speak(text: $0)
                        }
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
            self?.messagesCollectionView.scrollToBottom(animated: true)
        })
    }

    private func insertMessages(_ newMessages: [Message]) {
        self.messages.append(contentsOf: newMessages)
        self.messagesCollectionView.performBatchUpdates({
            let sections = newMessages.enumerated().map { self.messages.count - ($0.offset + 1) }
            let indexSet = IndexSet(sections)
//            messagesCollectionView.insertSections([self.messages.count - 1])
            messagesCollectionView.insertSections(indexSet)
            if self.messages.count >= 2 {
                self.messagesCollectionView.reloadSections([self.messages.count - newMessages.count - 1])
            }
        }, completion: { [weak self] _ in
            self?.messagesCollectionView.scrollToBottom(animated: true)
        })
    }

    private func isLastSectionVisible() -> Bool {
        guard !self.messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: self.messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    private func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard self.messages.indices.contains(indexPath.section - 1) else { return false }
        return self.messages[indexPath.section].sender.senderId == self.messages[indexPath.section - 1].sender.senderId
    }

    private func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard self.messages.indices.contains(indexPath.section + 1) else { return false }
        return self.messages[indexPath.section].sender.senderId == self.messages[indexPath.section + 1].sender.senderId
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

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if self.isFromCurrentSender(message: message) {
            return 0
        } else {
            return !self.isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        }
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return self.isNextMessageSameSender(at: indexPath) ? 0 : 5
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let message = self.messages[indexPath.section]
        let tailCorner: MessageStyle.TailCorner = message.sender.senderId == self.user.senderId ? .bottomRight : .bottomLeft
        if self.isNextMessageSameSender(at: indexPath) {
            return MessageStyle.bubble
        } else {
            return MessageStyle.bubbleTail(tailCorner, .pointedEdge)
        }

    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.date, .phoneNumber, .url]
    }

    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
//        guard !self.isNextMessageSameSender(at: indexPath) else {
//            avatarView.isHidden = true
//            return
//        }

        let message = self.messages[indexPath.section]


        switch message.sender.senderId {
        case self.bot.senderId:
            avatarView.image = UIImage(named: "arina")
        case self.system.senderId:
            avatarView.image = UIImage(named: "robot")
        case self.user.senderId:
            ()
        default:
            print("что-то пошло не так")
        }

        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
    }

    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
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
        case .activeWithHeight(let height):
            guard height > 100 else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3 - duration of messageInputBar layout animation
                self.messagesCollectionView.scrollToBottom(animated: true)
            }

            guard self.state == .keyboard, self.messageInputBar.leftStackViewWidthConstant == 0 else { return }
            let hideKeyboardButton = InputBarButtonItem(type: .system)
            hideKeyboardButton.setImage(UIImage(named: "hide_keyboard"), for: .normal)
            hideKeyboardButton.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 35, height: 35))
            }
            hideKeyboardButton.onTap { [weak self] in
                self?.messageInputBar.inputTextView.resignFirstResponder()
                self?.messageInputBar.setStackViewItems([], forStack: .left, animated: true)
                self?.messageInputBar.setLeftStackViewWidthConstant(to: 0, animated: true)
            }
            self.messageInputBar.setLeftStackViewWidthConstant(to: 35, animated: true)
            self.messageInputBar.setStackViewItems([hideKeyboardButton], forStack: .left, animated: true)
        case .hidden:
            self.debouncer.call()
            self.messageInputBar.setStackViewItems([], forStack: .left, animated: true)
            self.messageInputBar.setLeftStackViewWidthConstant(to: 0, animated: true)
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let locationCell = cell as? LocationMessageCell {
            guard let coordinate = locationCell.locationCoordinate else { return }

            let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            destination.name = "Пушкинский музей"

            MKMapItem.openMaps(
                with: [destination],
                launchOptions: [:]
            )
        }
    }

    func didSelectPhoneNumber(_ phoneNumber: String) {
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(phoneCallURL) {
            UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: nil)
        }
    }

    func didSelectDate(_ date: Date) {
        self.calendarManager.openEventCreator(date: date, showingHandler: { [weak self] viewController in
            self?.messageInputBar.isHidden = true
            self?.present(viewController, animated: true)
        }) { [weak self] viewController in
            viewController.dismiss(animated: true) {
                self?.messageInputBar.isHidden = false
            }
        }
    }

    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
}


extension ChatMessage {
    func mapToMessageKind() -> MessageKind? {
        switch self {
        case let plainTextMessage as PlainTextMessage:
            return .text(plainTextMessage.text)
        case let coordsMessage as CoordsMessage:
            return .location(LocationMessage(location: CLLocation(latitude: coordsMessage.latitude, longitude: coordsMessage.longitude)))
        case let audioMessage as SoundMessage:
            if let url = URL(string: audioMessage.audioURL) {
                return .audio(Audio(url: url))
            } else {
                return nil
            }
        case let imageMessage as ImageMessage:
            assertionFailure()
            return .text("")
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
