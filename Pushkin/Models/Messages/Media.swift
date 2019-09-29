//
//  Media.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    let url: URL? = nil
    let image: UIImage?
    let placeholderImage: UIImage
    let size: CGSize

    init(url: URL) {
        let data = (try? Data(contentsOf: url)) ?? Data()
        self.image = UIImage(data: data)
        self.placeholderImage = UIImage(named: "picture") ?? UIImage()
        self.size = CGSize(width: 200, height: 200)
    }
}
