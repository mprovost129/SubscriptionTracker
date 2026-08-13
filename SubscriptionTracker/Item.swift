//
//  Item.swift
//  SubscriptionTracker
//
//  Created by user301900 on 8/13/26.
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
