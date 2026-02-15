//
//  Item.swift
//  TypeZenMacOS
//
//  Created by 朱洪光 on 2026/2/15.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
