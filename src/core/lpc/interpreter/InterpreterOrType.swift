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

/// This class represents OrTypes for use in the Interpreter.
class InterpreterOrType: OrTypeProto {
    /// The type represented by `nil` expressions.
    static let nilType = InterpreterOrType(lhs: InterpreterType.mapping, rhs: InterpreterOrType(lhs: InterpreterType.object, rhs: InterpreterOrType(lhs: InterpreterType.string, rhs: InterpreterType.symbol)))
    
    let lhs: TypeProto?
    let rhs: TypeProto?
    
    /// Constructs this type from the given types.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand-side type.
    ///   - rhs: The right-hand-side type.
    init(lhs: TypeProto?, rhs: TypeProto?) {
        self.lhs = lhs
        self.rhs = rhs
    }
}
