/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022  mhahnFr
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
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    /// An array consisting of active MUD connection delegates.
    var delegates: Set<ConnectionDelegate> = []
    /// An array containing the recent connections mapped to their menu items in the recents menu.
    var recents: [NSMenuItem: ConnectionRecord] = [:]
    /// The menu with recent connections.
    @IBOutlet weak var recentsMenu: NSMenu!
    
    @IBAction func connectionClearRecentsAction(_ sender: NSMenuItem) {
        recentsMenu.items.removeSubrange(0 ..< recentsMenu.numberOfItems - 2)
        recents = [:]
        Settings.shared.recentConnections = []
    }
    
    @IBAction func windowCloseAction(_ sender: NSMenuItem) {
        NSApp.keyWindow?.performClose(self)
    }
    
    @IBAction func connectionCloseAction(_ sender: NSMenuItem) {
        if let current = NSApp.keyWindow?.delegate as? ConnectionDelegate {
            current.closeConnection()
        }
    }
    
    @IBAction func reconnectConnectionAction(_ sender: NSMenuItem) {
        if let current = NSApp.keyWindow?.delegate as? ConnectionDelegate {
            current.maybeReconnect()
        }
    }
    
    @IBAction func aboutAction(_ sender: NSMenuItem) {
        let contentView   = AboutView()
        let window        = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 150), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("About")
        window.isReleasedWhenClosed = false
        window.title                = "About \(Constants.APP_NAME)"
        window.contentView          = NSHostingView(rootView: contentView)
        
        window.center()
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func settingsAction(_ sender: NSMenuItem) {
        let contentView      = SettingsView()
        let settingsDelegate = SettingsViewDelegate()
        let window           = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 50), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("Settings")
        window.isReleasedWhenClosed = false
        window.title                = "\(Constants.APP_NAME): Settings"
        window.contentView          = NSHostingView(rootView: contentView)
        window.delegate             = settingsDelegate
        
        window.center()
        NSApp.runModal(for: window)
    }
    
    @IBAction func newConnectionAction(_ sender: NSMenuItem) {
        openNewConnection()
    }
    
    /// Prompts the user for the connection details and opens a new connection
    /// using the user provided information.
    ///
    /// Does nothing if the user cancels the prompt.
    private func openNewConnection() {
        guard let connection = promptConnection() else { return }
        
        let record    = openConnection(connection)
        let item      = findOrCreateRecentMenuItem(record: record)
        recents[item] = record
    }
    
    /// Opens the connection associated with the sender.
    ///
    /// - Parameter sender: The sender of the action.
    @objc private func openRecentConnection(_ sender: NSMenuItem) {
        let recent = recents[sender]!
        
        if let window = recent.delegate?.window {
            window.makeKeyAndOrderFront(self)
        } else {
            recents[sender] = openConnection(Connection(from: recent)!)
        }
    }

    /// Opens the given connection in a new window. The necessary delegate is saved.
    ///
    /// - Parameter connection: The connection that will be displayed.
    /// - Returns: A connection record containing the relevant information about the created connection view.
    private func openConnection(_ connection: Connection) -> ConnectionRecord {
        let window      = createConnectionWindow()
        let delegate    = ConnectionDelegate(for: connection, window: window)
        let contentView = ConnectionView(delegate: delegate)
        let record      = ConnectionRecord(from: connection, delegate: delegate)
        
        delegates.insert(delegate)
        Settings.shared.openConnections.append(record)
        
        delegate.onClose = {
            self.delegates.remove($0)
            Settings.shared.openConnections.removeAll { $0 == record }
        }
        
        window.title       = "\(Constants.APP_NAME): \(connection.name)"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate    = delegate
        
        window.setFrameAutosaveName(window.title)
        
        window.center()
        window.makeKeyAndOrderFront(self)
        
        return record
    }
    
    /// Prompts the user to enter the informations needed to establish a MUD connection.
    /// If the user aborts the process or the Connection could not be created, nil is returned.
    ///
    /// - Returns: A connection that is technically able to connect to a MUD or nil.
    private func promptConnection() -> Connection? {
        var toReturn: Connection?
        var userInfo: String?
        var delegate: ConnectionPromptDelegate
        
        repeat {
            let dialog = NSWindow(contentRect: NSMakeRect(0, 0, 300, 200), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            
            delegate = ConnectionPromptDelegate(with: dialog)
            delegate.userInfo = userInfo
            
            let contentView = ConnectionPromptView(delegate: delegate)
            
            dialog.contentView          = NSHostingView(rootView: contentView);
            dialog.delegate             = delegate
            dialog.title                = "\(Constants.APP_NAME): New connection"
            dialog.isReleasedWhenClosed = false
            
            NSApp.runModal(for: dialog)
            toReturn = Connection(hostname: delegate.hostname, port: delegate.port)
            if toReturn == nil { userInfo = "Invalid hostname or port!" }
        } while delegate.accepted && toReturn == nil
        
        return toReturn
    }
    
    /// Creates and returns a window suitable as UI for a MUD connection.
    ///
    /// - Returns: A new window.
    private func createConnectionWindow() -> NSWindow {
        let toReturn = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 750, height: 500), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        
        toReturn.isReleasedWhenClosed = false
        
        return toReturn
    }
    
    /// Fills the recents menu using the connection records stored in the settings.
    private func fillRecentsMenu() {
        for record in Settings.shared.recentConnections {
            let item      = NSMenuItem(title: "\(record.hostname):\(record.port)", action: #selector(openRecentConnection), keyEquivalent: "")
            recents[item] = record
            
            recentsMenu.items.insert(item, at: 0)
        }
    }

    /// Returns the menu item mapped to the given connection record.
    ///
    /// If no such menu item is found, it is created and appended to the
    /// recents menu.
    ///
    /// - Parameter record: The record whose mapped menu item is searched.
    /// - Returns: The mapped recent menu item.
    private func findOrCreateRecentMenuItem(record: ConnectionRecord) -> NSMenuItem {
        var recentItem: NSMenuItem?
        
        for (item, mappedRecord) in recents {
            if record == mappedRecord {
                recentItem = item
                break
            }
        }
        if recentItem == nil {
            recentItem = NSMenuItem(title: "\(record.hostname):\(record.port)", action: #selector(openRecentConnection), keyEquivalent: "")
            recentsMenu.items.insert(recentItem!, at: 0)
            Settings.shared.recentConnections.append(record)
        }
        return recentItem!
    }
    
    /// Reopens all connections whose records are passed.
    ///
    /// Updates the connection records in the recents menu accordingly.
    ///
    /// - Parameter connections: An array containing the connection records to reopen from.
    private func reopenConnections(_ connections: [ConnectionRecord]) {
        for record in connections {
            let recentItem      = findOrCreateRecentMenuItem(record: record)
            recents[recentItem] = openConnection(Connection(from: record)!)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        fillRecentsMenu()
        if Settings.shared.openConnections.isEmpty {
            openNewConnection()
        } else {
            let toReopen = Settings.shared.openConnections
            Settings.shared.openConnections = []
            reopenConnections(toReopen)
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Settings.shared.freeze()
        for delegate in delegates {
            if !delegate.maybeCloseConnection() {
                Settings.shared.unfreeze()
                return .terminateCancel
            }
            delegate.window?.close()
        }
        return .terminateNow
    }
}
