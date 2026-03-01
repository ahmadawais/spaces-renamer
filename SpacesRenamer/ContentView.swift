//
//  ContentView.swift
//  SpacesRenamer
//
//  Main SwiftUI view shown inside the MenuBarExtra popover window.
//

import SwiftUI

struct ContentView: View {
    var spaceManager: SpaceManager
    @State private var editedNames: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(spaceManager.monitors) { monitor in
                if spaceManager.monitors.count > 1 {
                    Text("Monitor \(monitor.id)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.leading, 10)
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(monitor.spaces) { space in
                            DesktopSnippetView(
                                index: space.index,
                                isCurrent: space.isCurrent,
                                name: binding(for: space.id, defaultValue: space.customName)
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
            }

            Divider()

            HStack {
                Button("Quit") { NSApp.terminate(nil) }
                Spacer()
                Button("Update Names") { saveNames() }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 12)
        .frame(minWidth: 300)
        .onAppear { loadCurrentNames() }
        .onChange(of: spaceManager.monitors) { _, _ in loadCurrentNames() }
    }

    // MARK: - Helpers

    private func binding(for uuid: String, defaultValue: String) -> Binding<String> {
        Binding(
            get: { editedNames[uuid] ?? defaultValue },
            set: { editedNames[uuid] = $0 }
        )
    }

    private func loadCurrentNames() {
        let saved = spaceManager.loadCustomNames()
        for monitor in spaceManager.monitors {
            for space in monitor.spaces {
                if editedNames[space.id] == nil {
                    editedNames[space.id] = saved[space.id] ?? ""
                }
            }
        }
    }

    private func saveNames() {
        spaceManager.saveCustomNames(editedNames)
    }
}
