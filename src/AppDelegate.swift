//
//  AppDelegate.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 4/21/22.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var connection: ClientConnection!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        connection = ClientConnection()
        let contentView = ContentView(connection: connection)

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 500, y: 500, width: 750, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        connection.close()
    }
}
