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

/// This protocol defines the interface for protocol plugins.
protocol ProtocolPlugin {
    /// Called when a new byte is received and this function returned true
    /// for the previous received byte or when the byte might be the beginning
    /// of an escape sequence.
    ///
    /// - Parameter byte: The byte that was received.
    /// - Parameter sender: A reference to the sender responsible for sending back a potential response.
    /// - Returns: Whether this plugin should be called for the next received byte.
    func process(byte: UInt8, sender: ConnectionSender) -> Bool
}
