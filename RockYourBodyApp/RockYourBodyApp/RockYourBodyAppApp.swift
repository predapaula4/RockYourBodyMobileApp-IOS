//
//  RockYourBodyAppApp.swift
//  RockYourBodyApp
//
//  Created by Preda Paula Maria  on 12.06.2026.
//

import SwiftUI

@main
struct RockYourBodyAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
