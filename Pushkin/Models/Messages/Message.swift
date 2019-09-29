//
//  Message.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit
import Foundation

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
