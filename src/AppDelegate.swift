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
    var window: NSWindow!
    var connection: ClientConnection!
    
    @IBAction func aboutAction(_ sender: NSMenuItem) {
        let contentView   = AboutView();
        let window        = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 150), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        window.setFrameAutosaveName("About")
        window.isReleasedWhenClosed = false;
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        connection = ClientConnection()
        let contentView = ContentView(connection: connection)

        window = NSWindow(
            contentRect: NSRect(x: 500, y: 500, width: 750, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.setFrameAutosaveName("SecretPathway")
        window.isReleasedWhenClosed = false
        window.contentView          = NSHostingView(rootView: contentView)
        window.title                = "SecretPathway"
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        connection.close()
    }
}
