//
//  RecipesSwiftDataApp.swift
//  RecipesSwiftData
//
//  Created by William Yeung on 6/20/23.
//

import SwiftUI
import SwiftData

@main
struct RecipesSwiftDataApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
        }
            .modelContainer(for: Recipe.self)
    }
}
