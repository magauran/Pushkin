//
//  CustomMessagesFlowLayout.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit

class CustomMessageSizeCalculator: MessageSizeCalculator {
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard case .custom(let model) = message.kind, let buttonsModels = model as? [ActionButtonModel] else { return .zero }
        let height = buttonsModels.count * 40 + (buttonsModels.count - 1) * 5
        return CGSize(width: 100, height: height)
    }
}

class ActionButtonsMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)

    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        guard
            let dataSource = messagesDataSource as? ChatViewController,
            dataSource.messages.indices.contains(indexPath.section)
        else { return super.cellSizeCalculatorForItem(at: indexPath) }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
}
