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

/// This class represents a variable definition as an AST node.
class ASTVariableDefinition: ASTExpression {
    /// The modifiers of this variable.
    let modifiers: [ASTExpression]
    /// The type of this variable.
    let returnType: ASTExpression?
    /// The name of this variable.
    let name: ASTExpression
    
    /// Constucts this AST node for variable definitions using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter modifiers: The declared modifiers of this variable.
    /// - Parameter type: The declared type of this variable.
    /// - Parameter name: The declared type of this variable.
    init(begin:     Int,
         end:       Int,
         modifiers: [ASTExpression],
         type:      ASTExpression?,
         name:      ASTExpression) {
        self.modifiers  = modifiers
        self.returnType = type
        self.name       = name
        
        var subs = modifiers
        if let type { subs.append(type) }
        subs.append(name)
        super.init(begin: begin, end: end, type: .VARIABLE_DEFINITION, subNodes: subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) modifiers:\n"
        
        modifiers.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        let indent = String(repeating: " ", count: indentation)
        if let returnType {
            buffer.append("\(indent)type:\n")
            buffer.append("\(returnType.describe(indentation + 4))\n")
        }
        buffer.append("\(indent)name:\n")
        buffer.append("\(name.describe(indentation + 4))")
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            for modifier in modifiers { await modifier.visit(visitor) }
            await returnType?.visit(visitor)
            await name.visit(visitor)
        }
    }
}
