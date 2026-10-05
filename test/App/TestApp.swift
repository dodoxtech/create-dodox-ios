//
//  TestApp.swift
//  test
//
//  Created by taio on 2026/10/05.
//

import SwiftUI

@main
struct TestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView(bootstrap: appDelegate.container.bootstrap)
                .environment(appDelegate.container)
        }
    }
}
