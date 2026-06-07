//
//  todaylevelupApp.swift
//  todaylevelup
//
//  Created by margarine on 6/7/26.
//

import SwiftUI

@main
struct todaylevelupApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    appState.saveData()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    appState.saveData()
                }
        }
    }
}
