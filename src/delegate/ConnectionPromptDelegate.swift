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

import AppKit
import SwiftUI

/// This class is a delegate for the windows prompting for the information
/// needed to construct a Connection instance from.
class ConnectionPromptDelegate: NSObject, NSWindowDelegate, ObservableObject {
    /// The hostname, filled by the associated view.
    @Published var hostname = ""
    /// The port, filled by the associated view.
    @Published var port     = ""
    
    /// Indicates whether the dialog has been accepted or dismissed.
    private(set) var accepted = false
    
    /// The reference to the associated NSWindow.
    private weak var window: NSWindow?
    
    /// Initializes a new instance with the given window to take the control of.
    ///
    /// - Parameter window: The window to be controlled by this delegate.
    init(with window: NSWindow?) {
        self.window = window
    }
    
    /// Marks this instance as accepted and closes the associated window if it is set.
    func accept() {
        accepted = true
        close()
    }
    
    /// Marks this instance as dismissed and closes the associated window if it is set.
    func dismiss() {
        accepted = false
        close()
    }
    
    /// Closes the associated window.
    func close() {
        window?.close()
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.stopModal()
    }
}
