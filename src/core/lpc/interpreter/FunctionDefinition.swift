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

/// This class represents a function definition.
class FunctionDefinition: Definition {
    /// The definitions of the parameters.
    let parameters: [Definition]
    /// Indicates whether the represented function can take variadic arguments.
    let variadic: Bool
    
    /// The string description of this function definition.
    override var string: String {
        var buffer = "\(name)("
        
        let last = parameters.last
        parameters.forEach {
            buffer.append("\($0.returnType.string) \($0.name)")
            if $0 !== last || variadic {
                buffer.append(", ")
            }
        }
        if variadic { buffer.append("...") }
        buffer.append(")")
        
        return buffer
    }
    
    /// Creates a function definition.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - name: The name.
    ///   - returnType: The return type.
    ///   - parameters: The parameter definitions.
    ///   - variadic: Whether the function can take variadic arguments.
    init(begin:      Int,
         name:       String,
         returnType: TypeProto,
         parameters: [Definition],
         variadic:   Bool,
         modifiers:  Modifier) {
        self.parameters = parameters
        self.variadic   = variadic
        
        super.init(begin: begin, returnType: returnType, name: name, kind: .FUNCTION_DEFINITION, modifiers: modifiers)
    }
}
