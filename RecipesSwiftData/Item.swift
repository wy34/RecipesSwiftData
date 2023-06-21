//
//  Item.swift
//  RecipesSwiftData
//
//  Created by William Yeung on 6/20/23.
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
