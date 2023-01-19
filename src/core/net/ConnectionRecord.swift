/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022 - 2023  mhahnFr
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
 * You should have received a copy of the GNU General Public License along with
 * this program, see the file LICENSE.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation

/// This class contains the relevant information about a connection and its associated view.
struct ConnectionRecord: Equatable {
    /// The used hostname or IP address.
    let hostname: String
    /// The used port.
    let port: Int
    /// Whether to use TLS for the connection.
    let secure: Bool
    
    /// A reference to the associated delegate.
    private(set) weak var delegate: ConnectionDelegate?
    
    /// Initializes this instance using the given information.
    ///
    /// - Parameter hostname: The hostname or the IP address.
    /// - Parameter port: The used port.
    /// - Parameter secure: Whether to use TLS for the connection.
    /// - Parameter delegate: The associated delegate.
    init(hostname: String, port: Int, secure: Bool, delegate: ConnectionDelegate?) {
        self.hostname = hostname
        self.port     = port
        self.delegate = delegate
        self.secure   = secure
    }
    
    /// Initializes this instance using the given connection and the given delegate.
    ///
    /// - Parameter connection: The connection to take the information from.
    /// - Parameter delegate: The associated delegate.
    init(from connection: Connection, delegate: ConnectionDelegate?) {
        self.init(hostname: connection.hostname, port: connection.port, secure: connection.secure, delegate: delegate)
    }
    
    /// Reads the record information from the given data.
    ///
    /// Returns nil if the data could not be parsed.
    ///
    /// - Parameter data: The data to read the information from.
    init?(from data: Data) {
        var advancer = 0
        
        guard let port = Int(from: data) else { return nil }
        advancer += 4
        
        guard data.count >= advancer + 4 else { return nil }
        
        guard let stringSize = Int(from: data.advanced(by: advancer)) else { return nil }
        advancer += 4
        
        guard data.count >= advancer + stringSize else { return nil }
        
        guard let hostname = String(data: data.subdata(in: advancer ..< (advancer + stringSize)), encoding: .unicode) else { return nil }
        advancer += stringSize
        
        guard data.count >= advancer + 1 else { return nil }
        
        self.init(hostname: hostname, port: port, secure: data[advancer] == 1, delegate: nil)
    }
    
    /// Dumps itself into a piece of data.
    ///
    /// The format is as follows: Int for the port, followed by a Int for
    /// the length of the hostname and then as many bytes for the hostname,
    /// encoded as unicode.
    ///
    /// - Returns: The dumped data.
    func dump() -> Data {
        var tmpData = Data()
        
        tmpData.append(port.dump())
        
        let stringData = hostname.data(using: .unicode)!
        tmpData.append(stringData.count.dump())
        tmpData.append(stringData)
        tmpData.append(secure ? 1 : 0)
        
        return tmpData
    }
    
    static func == (lhs: ConnectionRecord, rhs: ConnectionRecord) -> Bool {
        lhs.hostname == rhs.hostname && lhs.port == rhs.port
    }
    
    static func != (lhs: ConnectionRecord, rhs: ConnectionRecord) -> Bool {
        !(lhs == rhs)
    }
}
