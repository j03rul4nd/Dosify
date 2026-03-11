//
//  Item.swift
//  Dosify
//
//  Created by Ricardo Abraham Benitez Ruiz on 11/3/26.
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
