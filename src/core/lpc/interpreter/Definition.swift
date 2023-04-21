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

/// This class represents a definition of a property.
class Definition: Instruction {
    let begin: Int
    let returnType: TypeProto
    /// The name of the defined property.
    let name: String
    /// The type of property definition.
    let kind: ASTType
    
    var end: Int = -1
    
    /// Initializes this definition using the given information.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - returnType: The return type.
    ///   - name: The name of this property.
    ///   - kind: The AST type of this property definition.
    init(begin: Int, returnType: TypeProto, name: String, kind: ASTType) {
        self.begin      = begin
        self.returnType = returnType
        self.name       = name
        self.kind       = kind
    }
}
