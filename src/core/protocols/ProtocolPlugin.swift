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
    /// Returns whether the given byte is to be interpreted as a begin for
    /// sequences this plugin handles.
    ///
    /// It is called when the state machine tries to determine the type of a
    /// received byte. If this function returns true, incoming data is sent to
    /// this plugin's process function.
    ///
    /// - Parameter byte: The byte that might be the beginning byte.
    /// - Returns: Whether this plugin should be called for processing the next byte.
    func isBegin(byte: UInt8) -> Bool
    
    /// Called when a new byte is received and this plugin has indicated
    /// that it is responsible for handling the next incoming data.
    ///
    /// It will return whether the next incoming byte belongs to this plugin.
    ///
    /// - Parameter byte: The byte that was received.
    /// - Parameter sender: A reference to the sender responsible for sending back a potential response.
    /// - Returns: Whether this plugin should be called for the next received byte.
    func process(byte: UInt8, sender: ConnectionSender) -> Bool
}
