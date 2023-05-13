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

/// This class represents an interpretation array type.
class InterpreterArrayType: ArrayTypeProto {
    /// Indicates an array without underlying type.
    static let any = InterpreterArrayType(from: nil)
    
    let underlying: TypeProto?
    
    var string: String {
        if let underlying {
            return "\(underlying.string)[]"
        }
        return "any array"
    }
    
    /// Creates this type using the given underlying type.
    ///
    /// - Parameter underlying: The underlying type.
    init(from underlying: TypeProto?) {
        self.underlying = underlying
    }
}
