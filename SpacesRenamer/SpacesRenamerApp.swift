//
//  SpacesRenamerApp.swift
//  SpacesRenamer
//
//  Modern SwiftUI rewrite for macOS 14+ / Apple Silicon
//

import SwiftUI
import ServiceManagement

@main
struct SpacesRenamerApp: App {
    @State private var spaceManager = SpaceManager()

    init() {
        try? SMAppService.mainApp.register()
    }

    var body: some Scene {
        MenuBarExtra("Spaces Renamer", image: "StatusBarIcon") {
            ContentView(spaceManager: spaceManager)
        }
        .menuBarExtraStyle(.window)
    }
}
