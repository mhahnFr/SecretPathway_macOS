/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022 - 2023  mhahnFr
 *
 * This file is part of the SecretPathway_macOS. This program is free
 * software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program, see the file LICENSE.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation
import SwiftUI

/// This class contains all settings and is responsible for storing the
/// application state.
class Settings: ObservableObject {
    /// The single object of this class.
    static let shared = Settings()
    
    /// An array consisting of all currently opened connections.
    /// It is automatically retained by the underlying app storage.
    var openConnections: [ConnectionRecord] = [] {
        didSet {
            guard !frozen else { return }
            
            openConnectionsRaw = Settings.dumpConnectionRecords(openConnections)
        }
    }
    
    /// An array consisting of the recently opened connections.
    /// It is automatically retained by the underlying app storage.
    var recentConnections: [ConnectionRecord] = [] {
        didSet {
            guard !frozen else { return }
            
            recentConnectionsRaw = Settings.dumpConnectionRecords(recentConnections)
        }
    }

    var editorTheme: URL? {
        get {
            if let editorThemeCache { return editorThemeCache }
            
            guard let data = editorThemeBookmark else { return nil }
            
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale) {
                if url.startAccessingSecurityScopedResource() {
                    if stale {
                        editorThemeBookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    }
                    
                    editorThemeCache = url
                    return url
                } else {
                    editorThemeBookmark = nil
                }
            }
            return nil
        }
        set {
            editorThemeCache?.stopAccessingSecurityScopedResource()
            
            if let newValue {
                editorThemeBookmark = try? newValue.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            } else {
                editorThemeBookmark = nil
            }
            editorThemeCache = newValue
        }
    }
    
    /// The font size to be used globally.
    /// Automatically retained by the underlying app storage.
    @AppStorage(Constants.Storage.FONT_SIZE)
    var fontSize: Double = 12
    /// Whether to inline the editor into its controlling window.
    /// Automatically retained by the underlying app storage.
    @AppStorage(Constants.Storage.EDITOR_INLINED)
    var editorInlined: Bool = false
    /// Indicates whether the syntax highlighting of the LPC editor should be
    /// enabled by default.
    ///
    /// Automatially retained by the underlying app storage.
    @AppStorage(Constants.Storage.EDITOR_SYNTAX_HIGHLIGHT)
    var editorSyntaxHighlighting = true
    
    @AppStorage(Constants.Storage.EDITOR_THEME)
    private var editorThemeBookmark: Data?
    /// The raw data of the currently opened connections.
    @AppStorage(Constants.Storage.OPEN_CONNECTIONS)
    private var openConnectionsRaw: Data = Data()
    /// The raw data of the recently opened connections.
    @AppStorage(Constants.Storage.RECENT_CONNECTIONS)
    private var recentConnectionsRaw: Data = Data()
    
    /// Indicates whether changes made should be reflected into the underlying
    /// settings storage.
    private(set) var frozen = false
    
    private var editorThemeCache: URL? = nil
    
    /// Private initializer to prevent instancing this class from outside.
    ///
    /// Reads the settings from the storing location.
    private init() {
        openConnections   = Settings.readConnectionRecords(from: openConnectionsRaw)
        recentConnections = Settings.readConnectionRecords(from: recentConnectionsRaw)
    }
    
    /// Triggers an update of the underling settings storage.
    private func updateStorage() {
        openConnectionsRaw   = Settings.dumpConnectionRecords(openConnections)
        recentConnectionsRaw = Settings.dumpConnectionRecords(recentConnections)
    }
    
    /// When this function is called, all changes made are no longer reflected into
    /// the underlying settings storage.
    func freeze() {
        frozen = true
    }
    
    /// If the settings where frozen before, changes made AFTER this function is
    /// called are reflected into the underlying settings storage again.
    ///
    /// Updates the underlying settings storage.
    func unfreeze() {
        frozen = false
        updateStorage()
    }
    
    /// Dumps the given array of connection records into a data object.
    ///
    /// The format used: Int32    - amount of records
    ///                  Int32    - length of record
    ///                  [length] - record
    ///
    /// - Parameter records: The records to be dumped.
    /// - Returns: A block of data.
    static func dumpConnectionRecords(_ records: [ConnectionRecord]) -> Data {
        var tmpData = Data()
        
        tmpData.append(records.count.dump())
        
        for record in records {
            let recordDump = record.dump()
            tmpData.append(recordDump.count.dump())
            tmpData.append(recordDump)
        }
        return tmpData
    }
    
    /// Creates an array of connection records out of the given block of data.
    ///
    /// Returns an empty array if an error occurs while parsing.
    ///
    /// - Parameter data: The block of data to be parsed.
    /// - Returns: An array of connection records out of the block of data.
    static func readConnectionRecords(from data: Data) -> [ConnectionRecord] {
        var result: [ConnectionRecord] = []
        
        guard let amount = Int(from: data) else { return [] }
        
        var advancer = 4
        
        for _ in 0 ..< amount {
            guard data.count > advancer + 4 else { return [] }
            guard let size = Int(from: data.advanced(by: advancer)) else { return [] }
            advancer += 4
            
            guard data.count >= advancer + size else { return [] }
            
            guard let tmpRecord = ConnectionRecord(from: data.advanced(by: advancer)) else { return [] }
            advancer += size
            result.append(tmpRecord)
        }
        
        return result
    }
}
