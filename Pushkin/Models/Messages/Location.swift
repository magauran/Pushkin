//
//  Location.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Location: LocationItem {
    let location: CLLocation
    let size = CGSize(width: 270, height: 100)
}
