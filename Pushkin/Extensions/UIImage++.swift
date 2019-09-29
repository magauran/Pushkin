//
//  UIImage++.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageWith(color : UIColor) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }

        let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))

        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
}
