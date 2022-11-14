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

/// This class controls a view that acts as  user interface for a MUD connection.
class ConnectionDelegate: NSObject, NSWindowDelegate, ObservableObject {
    /// The content that was received on the connection.
    @Published private(set) var content = ""
    /// The prompt text.
    @Published private(set) var prompt:  String?
    /// A string that can hold a message displayed for the user.
    @Published private(set) var message: String?
    
    /// The connection that is managed by this delegate instance.
    private let connection: Connection
    /// The window that is controlled by this delegate instance.
    private weak var window: NSWindow?
    
    /// Initializes this instance using the given connection.
    ///
    /// - Parameter connection: The connection to be controlled by this instance.
    /// - Parameter window: The window optionally controlled by this instance.
    init(for connection: Connection, window: NSWindow? = nil) {
        self.connection = connection
        self.window     = window
        
        super.init()
        
        self.connection.stateListener = stateListener(_:)
        self.connection.start()
    }
    
    /// Displays a message according to the given state.
    ///
    /// - Parameter state: The state of the connection.
    private func stateListener(_ state: NWConnection.State) {
        let tmpMessage: String
        
        switch state {
        case .setup, .preparing:
            tmpMessage = "Connecting..."
        case .ready:
            tmpMessage = "Connected."
        case .cancelled:
            tmpMessage = "Disconnected!"
        case .waiting(let error), .failed(let error):
            tmpMessage = "Error! See console for more details."
            print(error)
        default:
            fatalError()
        }
        DispatchQueue.main.async {
            self.message = tmpMessage
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
        content.append(contentsOf: text)
        content.append("\n")
        
        guard let data = text.data(using: .utf8) else { return } // TODO: Error handling
        connection.send(data: data)
    }
    
    /// Closes the connection controlled by this delegate.
    func closeConnection() {
        connection.close()
    }
}
