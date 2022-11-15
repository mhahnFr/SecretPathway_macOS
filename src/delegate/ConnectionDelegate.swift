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
import Network
import SwiftUI

/// This class controls a view that acts as  user interface for a MUD connection.
class ConnectionDelegate: NSObject, NSWindowDelegate, ObservableObject, ConnectionListener {
    /// The content that was received on the connection.
    @Published private(set) var content = ""
    /// The prompt text.
    @Published private(set) var prompt:  String?
    /// A string that can hold a message displayed for the user.
    @Published private(set) var message: String?
    
    @Published private(set) var messageColor: Color?
    
    /// Callback to be called when the window this instance is controlling is definitively closing.
    var onClose: ((ConnectionDelegate) -> Void)?
    
    /// The window that is controlled by this delegate instance.
    private(set) weak var window: NSWindow?
    
    /// The connection that is managed by this delegate instance.
    private let connection: Connection
    
    /// Initializes this instance using the given connection.
    ///
    /// - Parameter connection: The connection to be controlled by this instance.
    /// - Parameter window: The window optionally controlled by this instance.
    init(for connection: Connection, window: NSWindow? = nil) {
        self.connection = connection
        self.window     = window
        
        super.init()
        
        self.connection.connectionListener = self
        self.connection.start()
    }
    
    /// Handles incoming data.
    ///
    /// - Parameter data: The new block of bytes
    internal func receive(data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return } // TODO: Decoding errors
        
        DispatchQueue.main.async {
            self.content.append(text)
        }
    }
    
    /// Displays a message according to the given state.
    ///
    /// - Parameter state: The state of the connection.
    internal func stateChanged(to state: NWConnection.State) {
        let tmpMessage: String
        
        var tmpColor: Color?
        var timeout:  Int?
        
        switch state {
        case .setup, .preparing:
            tmpMessage = "Connecting..."
        case .ready:
            tmpMessage = "Connected."
            tmpColor   = .green
            timeout    = 5
        case .cancelled:
            tmpMessage = "Disconnected!"
            tmpColor   = .yellow
        case .waiting(let error), .failed(let error):
            tmpMessage = "Error! See console for more details."
            tmpColor   = .red
            print(error)
        default:
            fatalError()
        }
                
        DispatchQueue.main.async {
            self.message      = tmpMessage
            self.messageColor = tmpColor
            if let timeout {
                Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { _ in
                    self.message      = nil
                    self.messageColor = nil
                }
            }
        }
    }
    
    /// Attempts to send the given string.
    ///
    /// - Parameter text: The text that should be sent.
    func send(_ text: String) {
        if let prompt {
            content.append(contentsOf: prompt)
            if prompt.last != " " { content.append(" ") }
        }
        let tmpText = text + "\n"
        content.append(contentsOf: tmpText)
        
        guard let data = tmpText.data(using: .utf8) else { return } // TODO: Error handling
        connection.send(data: data)
    }
    
    /// Closes the connection controlled by this delegate.
    func closeConnection() {
        connection.close()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // TODO: Prompt the user for connection closing
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        if let onClose { onClose(self) }
    }
}
