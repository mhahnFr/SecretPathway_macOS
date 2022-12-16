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

/// A enumeration containing the codes for the SecretPathwayProtocol (SPP).
enum SPProtocolConstants: String {
    /// The byte code indicating a SPP escape sequence.
    static let BEGIN: UInt8 = 0x2
    /// The byte code indicating a SPP escape sequence.
    static let END: UInt8 = 0x3
    
    case promptPassword = "pp"
    case promptNormal = "pn"
    case getWindowBounds = "gwb"
    case getWindowHeight = "gwh"
    case getWindowWidth = "gww"
    
    /// Returns whether the given character is the begin code of a SPP sequence.
    ///
    /// - Parameter c: The character to check.
    /// - Returns: Whether the character is the begin code of a SPP sequence.
    static func isSPPBegin(_ c: Character) -> Bool {
        guard let asciiValue = c.asciiValue else { return false }
        
        return asciiValue == BEGIN
    }
    
    /// Returns whether the given character is the end code of a SPP sequence.
    ///
    /// - Parameter c: The character to check.
    /// - Returns: Whether the character is the end code of a SPP sequence.
    static func isSPPEnd(_ c: Character) -> Bool {
        guard let asciiValue = c.asciiValue else { return false }
        
        return asciiValue == END
    }
}
