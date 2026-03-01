//
//  SpaceManager.swift
//  SpacesRenamer
//
//  Observable model that manages space data, monitors workspace changes,
//  and persists custom names via plist files compatible with the SIMBL bundle.
//

import Foundation
import Cocoa
import Observation

@Observable
final class SpaceManager {

    // MARK: - Types

    struct MonitorInfo: Identifiable, Equatable {
        let id: Int
        var spaces: [SpaceInfo]
    }

    struct SpaceInfo: Identifiable, Equatable {
        let id: String          // UUID from system
        var customName: String
        var isCurrent: Bool
        var managedSpaceID: Int
        var index: Int
    }

    // MARK: - Published State

    var monitors: [MonitorInfo] = []

    // MARK: - Paths (backwards-compatible with the SIMBL bundle)

    private static let libraryPath = NSSearchPathForDirectoriesInDomains(
        .libraryDirectory, .userDomainMask, true
    ).first!

    private static var containerDir: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.alexbeals.SpacesRenamer"
        return libraryPath + "/Containers/\(bundleID)"
    }

    static var customNamesPlistPath: String {
        containerDir + "/com.alexbeals.spacesrenamer.plist"
    }

    static var listOfSpacesPlistPath: String {
        containerDir + "/com.alexbeals.spacesrenamer.currentspaces.plist"
    }

    static var systemSpacesPath: String {
        libraryPath + "/Preferences/com.apple.spaces.plist"
    }

    // MARK: - Private

    private let conn: Int32
    private var fileMonitorSource: DispatchSourceFileSystemObject?

    // MARK: - Init

    init() {
        conn = _CGSDefaultConnection()
        ensureContainerDirectory()
        refreshSpaces()
        configureWorkspaceObservers()
        configureFileMonitor()
    }

    // MARK: - Public API

    func loadCustomNames() -> [String: String] {
        guard let dict = NSDictionary(contentsOfFile: Self.customNamesPlistPath),
              let names = dict["spaces_renaming"] as? [String: String]
        else { return [:] }
        return names
    }

    func saveCustomNames(_ names: [String: String]) {
        let dict = NSMutableDictionary(contentsOfFile: Self.customNamesPlistPath)
            ?? NSMutableDictionary()
        let mapping = (dict["spaces_renaming"] as? NSMutableDictionary)
            ?? NSMutableDictionary()

        for (uuid, name) in names {
            mapping.setValue(name, forKey: uuid)
        }

        dict["spaces_renaming"] = mapping
        dict.write(toFile: Self.customNamesPlistPath, atomically: true)
    }

    // MARK: - Space Refresh

    func refreshSpaces() {
        let info = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]

        let spacesDict = NSMutableDictionary()
        spacesDict.setValue(info, forKey: "Monitors")

        cleanUpRemovedSpaces(newInfo: info)

        let prev = NSDictionary(contentsOfFile: Self.listOfSpacesPlistPath)
        if spacesDict != prev {
            spacesDict.write(toFile: Self.listOfSpacesPlistPath, atomically: true)
        }

        let customNames = loadCustomNames()

        var newMonitors: [MonitorInfo] = []
        for (idx, monitor) in info.enumerated() {
            guard let monitorSpaces = monitor["Spaces"] as? [[String: AnyObject]] else { continue }
            let currentUUID = monitor.value(forKeyPath: "Current Space.uuid") as? String ?? ""

            var spaces: [SpaceInfo] = []
            for (spaceIdx, space) in monitorSpaces.enumerated() {
                let uuid = space["uuid"] as! String
                spaces.append(SpaceInfo(
                    id: uuid,
                    customName: customNames[uuid] ?? "",
                    isCurrent: uuid == currentUUID,
                    managedSpaceID: space["ManagedSpaceID"] as? Int ?? 0,
                    index: spaceIdx + 1
                ))
            }
            newMonitors.append(MonitorInfo(id: idx + 1, spaces: spaces))
        }

        DispatchQueue.main.async { [weak self] in
            self?.monitors = newMonitors
        }
    }

    // MARK: - Private Helpers

    private func ensureContainerDirectory() {
        try? FileManager.default.createDirectory(
            atPath: Self.containerDir,
            withIntermediateDirectories: true
        )

        // Bootstrap the spaces list from the system plist if first launch
        if !FileManager.default.fileExists(atPath: Self.listOfSpacesPlistPath),
           let sysDict = NSDictionary(contentsOfFile: Self.systemSpacesPath),
           let allSpaces = sysDict.value(
               forKeyPath: "SpacesDisplayConfiguration.Management Data.Monitors"
           ) as? NSArray {
            let listDict = NSMutableDictionary()
            listDict.setValue(allSpaces, forKey: "Monitors")
            listDict.write(toFile: Self.listOfSpacesPlistPath, atomically: true)
        }
    }

    private func cleanUpRemovedSpaces(newInfo: [NSDictionary]) {
        guard let prev = NSDictionary(contentsOfFile: Self.listOfSpacesPlistPath),
              let prevMonitors = prev["Monitors"] as? [[String: AnyObject]]
        else { return }

        var newUUIDs: Set<String> = []
        for monitor in newInfo {
            if let spaces = monitor["Spaces"] as? [[String: AnyObject]] {
                for space in spaces {
                    if let uuid = space["uuid"] as? String { newUUIDs.insert(uuid) }
                }
            }
        }

        var removedUUIDs: [String] = []
        for monitor in prevMonitors {
            if let spaces = monitor["Spaces"] as? [[String: AnyObject]] {
                for space in spaces {
                    if let uuid = space["uuid"] as? String, !newUUIDs.contains(uuid) {
                        removedUUIDs.append(uuid)
                    }
                }
            }
        }

        guard !removedUUIDs.isEmpty,
              let dict = NSMutableDictionary(contentsOfFile: Self.customNamesPlistPath),
              var renamed = dict["spaces_renaming"] as? [String: String]
        else { return }

        for uuid in removedUUIDs { renamed.removeValue(forKey: uuid) }
        dict["spaces_renaming"] = renamed
        dict.write(toFile: Self.customNamesPlistPath, atomically: true)
    }

    private func configureWorkspaceObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSpaces() }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSpaces() }
    }

    private func configureFileMonitor() {
        let fullPath = (Self.systemSpacesPath as NSString).expandingTildeInPath
        let fd = open(fullPath.cString(using: .utf8)!, O_EVTONLY)
        guard fd != -1 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .delete,
            queue: .global(qos: .default)
        )
        source.setEventHandler { [weak self] in
            source.cancel()
            self?.refreshSpaces()
            self?.configureFileMonitor()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileMonitorSource = source
    }
}
