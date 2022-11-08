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

/// Represents a MUD connection.
class Connection {
    /// The hostname or the IP address to connect to.
    let hostname: String
    /// The port to be used.
    let port: Int
    
    /// Creates a connection instance using the given inforamtion.
    ///
    /// Returns nil if the hostname is nil or the port is negative.
    ///
    /// - Parameter hostname: The hostname or the IP address to connect to.
    /// - Parameter port: The port to be used to connect to the given endpoint.
    init?(hostname: String, port: Int) {
        if hostname.isEmpty || port < 0 { return nil }
        
        self.hostname = hostname
        self.port     = port
    }
    
    /// Creates a connection instance using the given information.
    ///
    /// Returns nil if the hostname or the port is nil.
    ///
    /// - Parameter hostname: The hostname or the IP address to connect to.
    /// - Parameter port: The port to be used to connect to the given endpoint.
    convenience init?(hostname: String, port: String) {
        guard let port = Int(port) else { return nil }
        
        self.init(hostname: hostname, port: port)
    }
    
    func getName() -> String {
        return "no name"
    }
}
