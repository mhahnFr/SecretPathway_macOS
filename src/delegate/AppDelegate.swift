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
    var recents: [NSMenuItem: Connection] = [:]
    /// The menu with recent connections.
    @IBOutlet weak var recentsMenu: NSMenu!
    
    @IBAction func connectionClearRecentsAction(_ sender: NSMenuItem) {
        recentsMenu.items.removeSubrange(0 ..< recentsMenu.numberOfItems - 2)
        recents = [:]
    }
    
    @IBAction func windowCloseAction(_ sender: NSMenuItem) {
        NSApp.keyWindow?.close()
    }
    
    @IBAction func connectionCloseAction(_ sender: NSMenuItem) {
        if let current = NSApp.keyWindow?.delegate as? ConnectionDelegate {
            current.closeConnection()
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
        let window           = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 50), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("Settings")
        window.isReleasedWhenClosed = false
        window.title                = "\(Constants.APP_NAME): Settings"
        window.contentView          = NSHostingView(rootView: contentView)
        window.delegate             = settingsDelegate
        
        window.center()
        NSApp.runModal(for: window)
    }
    
    @IBAction func newConnectionAction(_ sender: NSMenuItem) {
        guard let connection = promptConnection() else { return }
        
        let item = NSMenuItem(title: connection.name, action: nil, keyEquivalent: "")
        item.action = #selector(openRecentConnection)
        
        recentsMenu.items.insert(item, at: 0)
        recents[item] = connection
        
        openConnection(connection)
    }
    
    /// Opens the connection associated with the sender.
    ///
    /// - Parameter sender: The sender of the action.
    @objc private func openRecentConnection(_ sender: NSMenuItem) {
        openConnection(Connection(from: recents[sender]!))
    }

    /// Opens the given connection in a new window. The necessary delegate is saved.
    ///
    /// - Parameter connection: The connection that will be displayed.
    private func openConnection(_ connection: Connection) {
        let window      = createConnectionWindow()
        let delegate    = ConnectionDelegate(for: connection, window: window)
        let contentView = ConnectionView(delegate: delegate)

        delegates.insert(delegate)
        delegate.onClose = { self.delegates.remove($0) }
        
        window.title       = "\(Constants.APP_NAME): \(connection.name)"
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate    = delegate
        
        window.setFrameAutosaveName(window.title)
        
        window.center()
        window.makeKeyAndOrderFront(self)
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // TODO: Load previous state, trigger openWindowAction by default
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        for delegate in delegates {
            delegate.closeConnection()
        }
    }
}
