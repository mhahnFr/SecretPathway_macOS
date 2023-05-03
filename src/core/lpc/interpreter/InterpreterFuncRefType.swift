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

class InterpreterFuncRefType: FunctionReferenceTypeProto {
    let returnType: TypeProto?
    let parameterTypes: [TypeProto?]
    let variadic: Bool
    
    var string: String {
        var buffer = ""
        
        if let returnType {
            buffer.append("\(returnType.string)")
        } else {
            buffer.append("<< unknown >>")
        }
        buffer.append("(")
        let last = parameterTypes.last
        parameterTypes.forEach {
            if let type = $0 {
                buffer.append("\(type.string)")
            } else {
                buffer.append("<< unknown >>")
            }
            if $0 !== last! || variadic {
                buffer.append(", ")
            }
        }
        if variadic { buffer.append("...") }
        buffer.append(")")
        
        return buffer
    }
    
    init(returnType: TypeProto?, parameterTypes: [TypeProto?], variadic: Bool) {
        self.returnType     = returnType
        self.parameterTypes = parameterTypes
        self.variadic       = variadic
    }
    
    func isAssignable(from other: TypeProto) -> Bool {
        guard let o = other as? FunctionReferenceTypeProto,
              (parameterTypes.count == o.parameterTypes.count ||
               (parameterTypes.count < o.parameterTypes.count && variadic)),
              let returnType,
              let oRet = o.returnType,
              returnType.isAssignable(from: oRet)
        else { return false }
        
        for i in 0 ..< parameterTypes.count {
            guard let type  = parameterTypes[i],
                  let oType = o.parameterTypes[i],
                  type.isAssignable(from: oType)
            else { return false }
        }
        return true
    }
}
