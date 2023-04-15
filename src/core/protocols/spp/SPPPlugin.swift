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

/// This class adds the SecretPathwayProtocol as a plugin.
class SPPPlugin: ProtocolPlugin {
    /// The buffer for a message in the SPP.
    private var buffer: [UInt8] = []
    
    internal func isBegin(byte: UInt8) -> Bool {
        return byte == 0x2
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        if byte == 0x03 {
            processBuffer()
            buffer = []
            return false
        }
        buffer.append(byte)
        return true
    }
    
    /// Handles the received SPP message.
    private func processBuffer() {
        print(String(bytes: buffer, encoding: .ascii) as Any)
    }
}
