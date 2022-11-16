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

import Network

/// Cases of this enumeration contain the underlying NWError. The enumeration case
/// itself indicates where the error happened.
enum ConnectionError {
    /// Indicates that the error happened in the receiving process.
    ///
    /// - Parameter error: The underlying NWError.
    case receiving(error: NWError)
    
    /// Indiciates that the error happened in the sending process.
    ///
    /// - Parameter error: The underlying NWError.
    case sending(error: NWError)
    
    /// Indicates that the error happened at an unspecified place.
    ///
    /// - Parameter error: The underlying NWError.
    case generic(error: NWError)
}
