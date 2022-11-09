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
    var delegates: [ConnectionDelegate] = []
    /// An array containing the recent connections mapped to their menu items in the recents menu.
    var recents: [NSMenuItem: Connection] = [:]
    /// The menu with recent connections.
    @IBOutlet weak var recentsMenu: NSMenu!
    
    @IBAction func aboutAction(_ sender: NSMenuItem) {
        let contentView   = AboutView()
        let window        = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 150), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("About")
        window.isReleasedWhenClosed = false
        window.title                = "About SecretPathway"
        window.contentView          = NSHostingView(rootView: contentView)
        
        window.center()
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func settingsAction(_ sender: NSMenuItem) {
        let contentView      = SettingsView()
        let settingsDelegate = SettingsViewDelegate()
        let window           = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 50), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("Settings")
        window.isReleasedWhenClosed = false
        window.title                = "Settings"
        window.contentView          = NSHostingView(rootView: contentView)
        window.delegate             = settingsDelegate
        
        window.center()
        NSApp.runModal(for: window)
    }
    
    @IBAction func newConnectionAction(_ sender: NSMenuItem) {
        guard let connection = promptConnection() else { return }
        
        let delegate = ConnectionDelegate(for: connection)
        delegates.append(delegate)
        
        let item = NSMenuItem(title: connection.getName(), action: nil, keyEquivalent: "")
        item.action = #selector(openRecentConnection)
        
        recentsMenu.addItem(item)
        recents[item] = connection
        
        let contentView = ConnectionView(delegate: delegate)
        
        let window = createConnectionWindow()
        
        window.title       = connection.getName()
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate    = delegate
        
        window.center()
        window.makeKeyAndOrderFront(sender)
    }
    
    /// Opens the connection associated with the sender.
    ///
    /// - Parameter sender: The sender of the action.
    @objc private func openRecentConnection(_ sender: NSMenuItem) {
        // TODO: Implement
        print(sender.title)
    }

    /// Prompts the user to enter the informations needed to establish a MUD connection.
    /// If the user aborts the process or the Connection could not be created, nil is returned.
    ///
    /// - Returns: A connection that is technically able to connect to a MUD or nil.
    private func promptConnection() -> Connection? {
        let dialog = NSWindow(contentRect: NSMakeRect(0, 0, 300, 200), styleMask: [.titled, .closable], backing: .buffered, defer: false)

        let delegate    = ConnectionPromptDelegate(with: dialog)
        let contentView = ConnectionPromptView(delegate: delegate)
        
        dialog.contentView          = NSHostingView(rootView: contentView);
        dialog.delegate             = delegate
        dialog.title                = "SecretPathway: New connection"
        dialog.isReleasedWhenClosed = false
        
        NSApp.runModal(for: dialog)
        return Connection(hostname: delegate.hostname, port: delegate.port)
    }
    
    /// Creates and returns a window suitable as UI for a MUD connection.
    ///
    /// - Returns: A new window.
    private func createConnectionWindow() -> NSWindow {
        let toReturn = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 750, height: 500), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        
        toReturn.setFrameAutosaveName("Window #\(delegates.count)")
        toReturn.isReleasedWhenClosed = false
        
        return toReturn
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // TODO: Load previous state, trigger openWindowAction by default
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // TODO: Notify all open connections
    }
}
