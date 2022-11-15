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

/// This protocol defines a listener responsible for handling state updates and
/// for receiving data.
protocol ConnectionListener: AnyObject {
    /// Called once a new block of data has been received.
    ///
    /// - Parameter data: The received block of data.
    func receive(data: Data)
    
    /// Called when the state of the underlying connection changes.
    ///
    /// - Parameter state: The new state of the underlying connection.
    func stateChanged(to state: NWConnection.State)
}
