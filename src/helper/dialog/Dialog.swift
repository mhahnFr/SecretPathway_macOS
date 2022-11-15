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

/// Represents a modal dialog that allows the user to click on one of multiple buttons.
class Dialog {
    /// The associated delegate.
    let delegate: DialogDelegate
    /// The modal window of this dialog.
    let window: NSWindow
    /// The SwiftUI view of this dialog.
    let view: DialogView
    
    /// Initilializes this instance using the provided parameters.
    ///
    /// - Parameter title: The title to be used for the dialog.
    /// - Parameter text: The main text to be displayed.
    /// - Parameter addition: The text to be displayed additionally, in a seperate line.
    /// - Parameter acceptButton: The text for the accept button, defaults to "OK"
    /// - Parameter cancelButton: The text of the cancel button
    /// - Parameter otherButtons: Using this variadic parameter, additional buttons can be added.
    init(title: String = Constants.APP_NAME, text: String = "", addition: String = "", acceptButton: String? = "OK", cancelButton: String? = nil, otherButtons: String...) {
        window   = NSWindow(contentRect: NSMakeRect(0, 0, 300, 200), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        delegate = DialogDelegate(for: window)
        
        delegate.message       = text
        delegate.addition      = addition
        delegate.acceptButton  = acceptButton
        delegate.dismissButton = cancelButton
        delegate.otherButtons  = otherButtons
        
        view = DialogView(delegate: delegate)
        
        window.isReleasedWhenClosed = false
        window.delegate             = delegate
        window.contentView          = NSHostingView(rootView: view)
        window.title                = title
    }
    
    /// Displays this dialog modally and returns whether the accept button was pressed.
    ///
    /// - Returns: Whether the dedicated accept button was pressed.
    func show() -> Bool {
        NSApp.runModal(for: window)
        return delegate.accepted
    }
}
