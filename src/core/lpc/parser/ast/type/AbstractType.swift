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

/// This protocol defines the functionality type representations should have.
protocol TypeProto {
    /// The string description of this type representation.
    var string: String { get }
    
    /// Returns whether variables of this type can be assigned
    /// values of variables of the given other type.
    ///
    /// - Parameter other: The type of the right hand side expression.
    /// - Returns: Whether this type can be assigned from the given one.
    func isAssignable(from other: TypeProto) -> Bool
}

/// Represents a type definition as an AST node.
typealias AbstractType = TypeProto & ASTExpression
