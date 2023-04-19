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

/// This class represents a function reference type as an AST node.
class FunctionReferenceType: AbstractType {
    /// The return type of the referenced function.
    let returnType: ASTExpression
    /// The types of the parameters of the referenced function.
    let parameterTypes: [ASTExpression]
    /// Indicates whether the referenced function has variadic parameters.
    let variadic: Bool
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter returnType: The return type of the referenced function.
    /// - Parameter parameterTypes: The types of the parameters of the referenced function.
    /// - Parameter variadic: Indicates whether the referenced function has variadic arguments.
    /// - Parameter end: The end position.
    init(returnType:     ASTExpression,
         parameterTypes: [ASTExpression],
         variadic:       Bool = false,
         end:            Int) {
        self.returnType     = returnType
        self.parameterTypes = parameterTypes
        self.variadic       = variadic
        
        super.init(begin: returnType.begin, end: end, type: .FUNCTION_REFERENCE)
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        var buffer = "\(super.describe(indentation)) return type:\n\(returnType.describe(indentation + 4))\n" +
                     "\(indent)parameter types:\n"
        
        parameterTypes.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        buffer.append("\(indent)variadic: \(variadic)")
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            returnType.visit(visitor)
            parameterTypes.forEach { $0.visit(visitor) }
        }
    }
}
