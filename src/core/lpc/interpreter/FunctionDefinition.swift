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

class FunctionDefinition: Definition {
    let parameters: [Definition]
    let variadic: Bool
    
    var string: String {
        var buffer = "\(name)("
        
        for (i, parameter) in parameters.enumerated() {
            let typeString: String
//            if let rt = parameter.returnType, let s = rt.string {
//                typeString = s
//            } else {
                typeString = "<< unknown >>"
//            }
            buffer.append("\(typeString) \(parameter.name)")
            if i + 1 < parameters.count || variadic {
                buffer.append(", ")
            }
        }
        if variadic { buffer.append("...") }
        buffer.append(")")
        
        return buffer
    }
    
    init(begin:      Int,
         name:       String,
         returnType: TypeProto,
         parameters: [Definition],
         variadic:   Bool) {
        self.parameters = parameters
        self.variadic   = variadic
        
        super.init(begin: begin, returnType: returnType, name: name, kind: .FUNCTION_DEFINITION)
    }
}
