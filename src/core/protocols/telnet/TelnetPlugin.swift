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

/// This plugin adds telnet functionality.
class TelnetPlugin: ProtocolPlugin {
    internal func isBegin(byte: UInt8) -> Bool {
        return byte == 0xff
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        print(byte)
        switch byte {
        case 240: return false
        case 250, 251, 252, 253, 254: return true
        default: return false
        }
    }
}
