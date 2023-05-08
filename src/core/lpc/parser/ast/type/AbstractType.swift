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
protocol TypeProto: AnyObject {
    /// The string description of this type representation.
    var string: String { get }
    
    /// Returns whether variables of this type can be assigned
    /// values of variables of the given other type.
    ///
    /// - Parameter other: The type of the right hand side expression.
    /// - Returns: Whether this type can be assigned from the given one.
    func isAssignable(from other: TypeProto) -> Bool
    
    /// Returns whether variables of this type can be assigned
    /// values of variables of the given other type.
    ///
    /// - Parameters:
    ///   - other: The type of the right hand side expression.
    ///   - loader: The file loader used to resolve type annotations.
    /// - Returns: Whether this type can be assigned from the given one.
    func isAssignable(from other: TypeProto, loader: LPCFileManager?) async -> Bool
}

/// This extension adds a default functionality as convenience.
extension TypeProto {
    func isAssignable(from other: TypeProto, loader: LPCFileManager?) async -> Bool {
        isAssignable(from: other)
    }
}

/// This protocol defines the functionality array type representations should have.
protocol ArrayTypeProto: TypeProto {
    /// The underlying type.
    var underlying: TypeProto? { get }
}

/// This protocoll defines the base of a function reference type.
protocol FunctionReferenceTypeProto: TypeProto {
    /// The return type of the referenced function.
    var returnType: TypeProto? { get }
    /// The types of the parameters of the referenced function.
    var parameterTypes: [TypeProto?] { get }
    /// Indicates whether the referenced function is variadic.
    var variadic: Bool { get }
}

/// Represents a type definition as an AST node.
typealias AbstractType = TypeProto & ASTExpression
