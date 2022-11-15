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

/// The delegate class for a modal dialog.
class DialogDelegate: NSObject, NSWindowDelegate, ObservableObject {
    /// The main message displayed by the view.
    @Published var message  = ""
    /// The additional text.
    @Published var addition = ""
    /// The text label of the accept button. Not displayed if nil.
    @Published var acceptButton: String?
    /// The text label for the dismiss button. Not displayed if nil.
    @Published var dismissButton: String?
    /// Other buttons that are displayed between the dismiss button and the accept button.
    @Published var otherButtons: [String] = []
    
    /// Indicates whether the user has pressed the accept button.
    private(set) var accepted = false
    /// The button the user clicked on.
    private(set) var usedButton: String?
    
    /// The window this delegate controls.
    private weak var window: NSWindow?
    
    /// Initializes this instance for the given window.
    ///
    /// - Parameter window: The window this instance should control.
    init(for window: NSWindow?) {
        self.window = window
    }
    
    /// Marks this instance as accepted and closes the associated window.
    func accept() {
        accepted = true
        usedButton = acceptButton
        close()
    }
    
    /// Marks this instance as not accepted and closes the associated window.
    func dismiss() {
        accepted = false
        usedButton = dismissButton
        close()
    }
    
    /// Sets the used button to the given one and closes the associated window.
    func action(for button: String) {
        usedButton = button
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
