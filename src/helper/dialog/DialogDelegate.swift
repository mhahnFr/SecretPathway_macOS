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

class DialogDelegate: NSObject, NSWindowDelegate, ObservableObject {
    
    @Published var message  = ""
    @Published var addition = ""
    @Published var acceptButton: String?
    @Published var dismissButton: String?
    @Published var otherButtons: [String] = []
    
    private(set) var accepted = false
    private(set) var usedButton: String?
    
    private weak var window: NSWindow?
    
    init(for window: NSWindow?) {
        self.window = window
    }
    
    func accept() {
        accepted = true
        usedButton = acceptButton
        close()
    }
    
    func dismiss() {
        accepted = false
        usedButton = dismissButton
        close()
    }
    
    func action(for button: String) {
        usedButton = button
        close()
    }
    
    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.stopModal()
    }
}
