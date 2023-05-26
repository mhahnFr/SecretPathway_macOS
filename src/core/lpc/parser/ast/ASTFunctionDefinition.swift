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

/// This class represents a function definition as an AST node.
class ASTFunctionDefinition: ASTExpression {
    /// The declared modifiers of this function.
    let modifiers: [ASTExpression]
    /// The declared return type of this function.
    let returnType: ASTExpression
    /// The declared name of this function.
    let name: ASTExpression
    /// The declared parameters.
    let parameters: [ASTExpression]
    /// The body of this declared function.
    let body: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter modifiers: The declared modifiers.
    /// - Parameter type: The declared type.
    /// - Parameter name: The declared name.
    /// - Parameter parameters: The declared parameters.
    /// - Parameter body: The body of the function.
    init(modifiers:  [ASTExpression],
         type:       ASTExpression,
         name:       ASTExpression,
         parameters: [ASTExpression],
         body:       ASTExpression) {
        self.modifiers  = modifiers
        self.returnType = type
        self.name       = name
        self.parameters = parameters
        self.body       = body
        
        var subs = [ASTExpression]()
        subs.append(contentsOf: modifiers)
        subs.append(type)
        subs.append(name)
        subs.append(contentsOf: parameters)
        subs.append(body)
        
        super.init(begin:    modifiers.first?.begin ?? type.begin,
                   end:      body.end,
                   type:     .FUNCTION_DEFINITION,
                   subNodes: subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) modifiers:\n"
        
        modifiers.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        let indent = String(repeating: " ", count: indentation)
        buffer.append("\(indent)return type:\n\(returnType.describe(indentation + 4))\n\(indent)name:\n\(name.describe(indentation))\n\(indent)parameters:\n")
        
        parameters.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        buffer.append("\(indent)body:\n\(body.describe(indentation + 4))")
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            for modifier in modifiers { await modifier.visit(visitor) }
            await returnType.visit(visitor)
            await name.visit(visitor)
            for parameter in parameters { await parameter.visit(visitor) }
            await body.visit(visitor)
        }
    }
}
