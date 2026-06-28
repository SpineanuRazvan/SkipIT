//
//  Item.swift
//  SkipIT
//
//  Created by Razvan Spineanu on 17.03.2026.
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
