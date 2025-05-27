//
//  Item.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
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
