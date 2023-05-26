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

/// This class represents a `while` statement as an AST node.
class ASTWhile: ASTExpression {
    /// The condition expression.
    let condition: ASTExpression
    /// The loop's body.
    let body: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter condition: The condition.
    /// - Parameter body: The body.
    /// - Parameter doWhile: Whether this loop is a `do while` loop.
    init(begin:     Int,
         condition: ASTExpression,
         body:      ASTExpression,
         doWhile:   Bool = false) {
        self.condition = condition
        self.body      = body
        
        super.init(begin: begin, end: body.end, type: doWhile ? .DO_WHILE : .AST_WHILE, subNodes: [condition, body])
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) Condition:\n\(condition.describe(indentation + 4))\n" +
        "\(String(repeating: " ", count: indentation))Body:\n" +
        body.describe(indentation + 4)
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await condition.visit(visitor)
            await body.visit(visitor)
        }
    }
}
