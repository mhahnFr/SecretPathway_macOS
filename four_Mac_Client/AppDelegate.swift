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


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Settings.shared.windowWidth, height: Settings.shared.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        if (Settings.shared.windowPositionX == -1 ||
            Settings.shared.windowPositionY == -1) {
            window.center()
        } else {
            window.setFrameOrigin(NSPoint(x: Settings.shared.windowPositionX, y: Settings.shared.windowPositionY))
        }
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

