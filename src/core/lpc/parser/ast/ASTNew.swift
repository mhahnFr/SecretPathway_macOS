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

/// This class represents a new expression as an AST node.
class ASTNew: ASTExpression {
    /// The instancing expression.
    let instancingExpression: ASTExpression
    /// The optional argument expressions.
    let arguments: [ASTExpression]?
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter instancingExpression: The instancing expression.
    /// - Parameter arguments: The optional argument expressions.
    init(begin:                Int,
         end:                  Int,
         instancingExpression: ASTExpression,
         arguments:            [ASTExpression]?) {
        self.instancingExpression = instancingExpression
        self.arguments            = arguments
        
        super.init(begin: begin, end: end, type: .AST_NEW)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) what:\n" +
                     "\(instancingExpression.describe(indentation + 4))\n"
        if let arguments {
            buffer.append("\(String(repeating: " ", count: indentation))arguments:\n")
            arguments.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        }
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await instancingExpression.visit(visitor)
            if let arguments {
                for argument in arguments { await argument.visit(visitor) }
            }
        }
    }
}
