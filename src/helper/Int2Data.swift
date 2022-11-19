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

/// An extension adding dumping possibilites to normal ints.
extension Int {
    /// Initializes an int from the given block of data.
    ///
    /// Returns nil if the given block of data contains less than 4 bytes.
    ///
    /// - Parameter data: The data to read the int from.
    init?(from data: Data) {
        guard data.count >= 4 else { return nil }
        
        self.init()
        
        self = (Int(data[0]) & 0xff) << 24
             | (Int(data[1]) & 0xff) << 16
             | (Int(data[2]) & 0xff) <<  8
             | (Int(data[3]) & 0xff) <<  0
    }
    
    /// Dumps this integer into a block of data containing four bytes.
    ///
    /// - Returns: A block of data representing this integer.
    func dump() -> Data {
        var tmpData = Data()
        
        tmpData.append(Data(repeating: UInt8(self >> 24 & 0xff), count: 1))
        tmpData.append(Data(repeating: UInt8(self >> 16 & 0xff), count: 1))
        tmpData.append(Data(repeating: UInt8(self >>  8 & 0xff), count: 1))
        tmpData.append(Data(repeating: UInt8(self >>  0 & 0xff), count: 1))

        return tmpData
    }
}
