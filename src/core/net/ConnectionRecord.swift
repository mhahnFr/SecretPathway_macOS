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

/// This class contains the relevant information about a connection and its associated view.
struct ConnectionRecord: Equatable {
    /// The used hostname or IP address.
    let hostname: String
    /// The used port.
    let port: Int
    
    /// A reference to the associated delegate.
    private(set) weak var delegate: ConnectionDelegate?
    
    /// Initializes this instance using the given information.
    ///
    /// - Parameter hostname: The hostname or the IP address.
    /// - Parameter port: The used port.
    /// - Parameter delegate: The associated delegate.
    init(hostname: String, port: Int, delegate: ConnectionDelegate?) {
        self.hostname = hostname
        self.port     = port
        self.delegate = delegate
    }
    
    /// Initializes this instance using the given connection and the given delegate.
    ///
    /// - Parameter connection: The connection to take the information from.
    /// - Parameter delegate: The associated delegate.
    init(from connection: Connection, delegate: ConnectionDelegate?) {
        self.init(hostname: connection.hostname, port: connection.port, delegate: delegate)
    }
    
    static func == (lhs: ConnectionRecord, rhs: ConnectionRecord) -> Bool {
        lhs.hostname == rhs.hostname && lhs.port == rhs.port
    }
    
    static func != (lhs: ConnectionRecord, rhs: ConnectionRecord) -> Bool {
        !(lhs == rhs)
    }
}
