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

/// This class represents a class definition as an AST node.
class ASTClass: ASTExpression {
    /// The name expression.
    let name: ASTExpression
    /// The inheritance expression if this class was defined in the shorthand form.
    let inheritance: ASTExpression?
    /// The statements inside the class.
    let statements: [ASTExpression]
    
    /// Initializes this AST node as a class in the shorthand form.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter name: The name expression.
    /// - Parameter inheritance: The optionally present inheritance expression.
    init(begin: Int, name: ASTExpression, inheritance: ASTExpression?) {
        self.name        = name
        self.inheritance = inheritance
        self.statements  = []
        
        var subs = [name]
        if let inheritance { subs.append(inheritance) }
        super.init(begin: begin, end: inheritance?.end ?? name.end, type: .AST_CLASS, subNodes: subs)
    }
    
    /// Initializes this AST node as a class in the traditional form.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter name: The name expression.
    /// - Parameter statements: The statements defined in this class.
    init(begin: Int, name: ASTExpression, statements: [ASTExpression]) {
        self.name        = name
        self.statements  = statements
        self.inheritance = nil
        
        var subs = [name]
        subs.append(contentsOf: statements)
        super.init(begin: begin, end: statements.last?.end ?? name.end, type: .AST_CLASS, subNodes: subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        var buffer = "\(super.describe(indentation)) Name:\n\(name.describe(indentation + 4))\n"
        
        if let inheritance {
            buffer.append("\(indent)Inherit:\n\(inheritance.describe(indentation + 4))")
            if !statements.isEmpty {
                buffer.append("\n")
            }
        }
        if !statements.isEmpty {
            buffer.append("\(indent)Statements:\n")
            for statement in statements {
                buffer.append(statement.describe(indentation + 4) + "\n")
            }
        }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await name.visit(visitor)
            await inheritance?.visit(visitor)
            for statement in statements {
                await statement.visit(visitor)
            }
        }
    }
}
