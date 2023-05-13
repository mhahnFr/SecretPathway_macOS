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

/// This class represents an interpreter function reference type.
class InterpreterFuncRefType: FunctionReferenceTypeProto {
    let returnType: TypeProto?
    let parameterTypes: [TypeProto?]
    let variadic: Bool
    
    /// Initializes this type representation using the given information.
    ///
    /// - Parameters:
    ///   - returnType: The return type of the referenced function.
    ///   - parameterTypes: The parameter types of the referenced function.
    ///   - variadic: Indicates whether the referenced function has variadic parameters.
    init(returnType: TypeProto?, parameterTypes: [TypeProto?], variadic: Bool) {
        self.returnType     = returnType
        self.parameterTypes = parameterTypes
        self.variadic       = variadic
    }
}
