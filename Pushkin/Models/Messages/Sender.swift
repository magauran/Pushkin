//
//  Sender.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import protocol MessageKit.SenderType
import struct UIKit.UUID

struct Sender: SenderType {
    let senderId = UUID().uuidString
    let displayName: String

    init(displayName: String) {
        self.displayName = displayName
    }
}
