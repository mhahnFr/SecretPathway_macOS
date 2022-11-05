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
    var delegates: [ConnectionDelegate] = []
    
    @IBAction func aboutAction(_ sender: NSMenuItem) {
        let contentView   = AboutView();
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
        
        let contentView = ConnectionView(for: connection)
        
        let window = createConnectionWindow()
        
        window.title       = connection.getName()
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate    = delegate
        
        window.center()
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func newWindowAction(_ sender: NSMenuItem) {
        let window      = createConnectionWindow()
        let contentView = ConnectionView(for: nil)
        
        window.title       = "New connection..."
        window.contentView = NSHostingView(rootView: contentView)
        
        window.center()
        window.makeKeyAndOrderFront(sender)
        
        if let connection = promptConnection(in: window) {
            let delegate = ConnectionDelegate(for: connection)
            delegates.append(delegate)
            window.delegate = delegate
        } else {
            window.close()
        }
    }
    
    /// Prompts the user to enter the informations needed to establish a MUD connection.
    /// If the user aborts the process or the Connection could not be created, nil is returned.
    ///
    /// - Parameter window: The window in which the dialog should be embedded.
    /// - Returns: A connection that is technically able to connect to a MUD or nil.
    private func promptConnection(in window: NSWindow? = nil) -> Connection? {
        let dialog = NSWindow(contentRect: NSMakeRect(0, 0, 300, 200), styleMask: [.titled, .closable], backing: .buffered, defer: false)

        let delegate    = ConnectionPromptDelegate()
        let contentView = ConnectionPromptView(delegate: delegate)
        
        dialog.contentView          = NSHostingView(rootView: contentView);
        dialog.delegate             = delegate
        dialog.title                = "SecretPathway: New connection"
        dialog.isReleasedWhenClosed = false
        
        var toReturn: Connection?
        
        func dialogHandler(with response: NSApplication.ModalResponse) {
            // TODO: Get the data
        }
        
        if let window {
            window.beginSheet(window, completionHandler: dialogHandler(with:))
        } else {
            dialogHandler(with: NSApp.runModal(for: dialog))
        }
        return toReturn
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
