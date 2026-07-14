//
//  Item.swift
//  KinCare
//
//  Created by Zelan Eroz Espanto on 7/14/26.
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
