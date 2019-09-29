//
//  Audio.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import MessageKit
import AVFoundation

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
