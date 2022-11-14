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

import Foundation
import Network

/// Represents a MUD connection.
class Connection {
    /// The hostname or the IP address to connect to.
    let hostname: String
    /// The port to be used.
    let port: Int
    
    /// The state update handler connected to the underlying connection.
    var stateListener: ((NWConnection.State) -> Void)? {
        get {
            connection.stateUpdateHandler
        }
        set {
            connection.stateUpdateHandler = newValue
        }
    }
    
    /// The name of the connection.
    ///
    /// Defaults to the hostname or the IP address and the port.
    private(set) var name: String
    
    /// The underlying network connection.
    private let connection: NWConnection
    
    /// Creates a connection instance using the given inforamtion.
    ///
    /// Returns nil if the hostname is nil or the port is negative.
    ///
    /// - Parameter hostname: The hostname or the IP address to connect to.
    /// - Parameter port: The port to be used to connect to the given endpoint.
    init?(hostname: String, port: Int) {
        guard !hostname.isEmpty && port >= 0 else { return nil }
        
        self.hostname = hostname
        self.port     = port
        self.name     = "\(self.hostname):\(self.port)"
        
        guard let portNo = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        
        let host: NWEndpoint.Host
        
        if let address = IPv6Address(hostname) {
            host = .ipv6(address)
        } else if let address = IPv4Address(hostname) {
            host = .ipv4(address)
        } else {
            host = .name(hostname, nil)
        }
        connection = NWConnection(host: host, port: portNo, using: .tcp)
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
    
    /// Opens the connection using a new queue, named with the name of this instance.
    func start() {
        connection.start(queue: .init(label: name))
    }
    
    /// Attempts to send the given data.
    ///
    /// - Parameter data: The data that should be sent.
    func send(data: Data) {
        // TODO: Implement
        print(data)
    }
    
    /// Closes the underlying connection gracefully.
    func close() {
        // TODO: Implement
    }
}
