/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2023  mhahnFr
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

/// This class represents a type poiting to the current context.
class ThisType: InterpreterType {
    /// A general `this` type.
    static let this = ThisType(type: .OBJECT)
    
    private override init(type: TokenType?, file name: String? = nil) {
        super.init(type: type, file: name)
    }
    
    /// Initializes this `this` type using the optional file name.
    ///
    /// - Parameter name: The file name representation of the current context.
    convenience init(file name: String? = nil) {
        self.init(type: .OBJECT, file: name)
    }
}
