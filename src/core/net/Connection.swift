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
    
    /// The listener handling connection state updates and receiving data.
    ///
    /// If data has been received before this variable has been set to something else
    /// than nil, the buffered data is passed immediately to the newly set listener.
    weak var connectionListener: ConnectionListener? {
        didSet {
            guard let connectionListener else { return }
            
            if !buffer.isEmpty {
                connectionListener.receive(data: buffer)
                buffer = Data()
            }
        }
    }
    
    /// The name of the connection.
    ///
    /// Defaults to the hostname or the IP address and the port.
    private(set) var name: String
    /// Indicates whether this connection has been closed.
    private(set) var isClosed = false
    
    /// The underlying network connection.
    private let connection: NWConnection
    
    /// A buffer that is filled as long as data is received but no content listener is set.
    private var buffer = Data()
    
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
        connection.stateUpdateHandler = stateUpdateHandler
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
    
    /// Creates a connection instance using the given record.
    ///
    /// - Parameter record: The record to take the necessary information from.
    convenience init?(from record: ConnectionRecord) {
        self.init(hostname: record.hostname, port: record.port)
    }

    /// Creates a new connection instance from the given one.
    ///
    /// - Parameter connection: The connection whose information to use.
    convenience init(from connection: Connection) {
        self.init(hostname: connection.hostname, port: connection.port)!
    }
    
    /// Handles state updates of the underlying connection.
    ///
    /// Calls the state listener if set.
    ///
    /// - Parameter state: The new state of the connection.
    private func stateUpdateHandler(_ state: NWConnection.State) {
        if state == .ready { receive() }
        
        isClosed = state == .cancelled
        
        connectionListener?.stateChanged(to: state)
    }
    
    /// Receives a block of bytes.
    ///
    /// Upon receiption, if the content listener is set, it is called with the newly received
    /// block of bytes. Otherwise, the received bytes are buffered.
    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: .max) { data, context, complete, error in
            if let data {
                if let listener = self.connectionListener {
                    listener.receive(data: data)
                } else {
                    self.buffer.append(data)
                }
            }
            // TODO: Error management
            self.receive()
        }
    }
    
    /// Opens the connection using a new queue, named with the name of this instance.
    func start() {
        connection.start(queue: .init(label: name))
    }
    
    /// Restarts the underlying connection.
    func retry() {
        connection.restart()
    }
    
    /// Attempts to send the given data.
    ///
    /// - Parameter data: The data that should be sent.
    func send(data: Data) {
        connection.send(content: data, completion: .contentProcessed({ error in
            // TODO: Implement
        }))
    }
    
    /// Closes the underlying connection gracefully.
    func close() {
        connection.cancel()
    }
}
