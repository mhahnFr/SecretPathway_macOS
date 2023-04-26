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

/// This class represents a `for` loop as an AST node.
class ASTFor: ASTExpression {
    /// The initial expression.
    let initExpression: ASTExpression
    /// The conditional expression.
    let condition: ASTExpression
    /// The after expression.
    let afterExpression: ASTExpression
    /// The body.
    let body: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter initExpression: The initial expression.
    /// - Parameter condition: The conditional expression.
    /// - Parameter afterExpression: The after expression.
    /// - Parameter body: The body.
    init(begin:           Int,
         initExpression:  ASTExpression,
         condition:       ASTExpression,
         afterExpression: ASTExpression,
         body:            ASTExpression) {
        self.initExpression  = initExpression
        self.condition       = condition
        self.afterExpression = afterExpression
        self.body            = body
        
        super.init(begin: begin, end: body.end, type: .AST_FOR)
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        return "\(super.describe(indentation)) Initial:\n" +
               "\(initExpression.describe(indentation + 4))\n" +
               "\(indent)Condition:\n" +
               "\(condition.describe(indentation + 4))\n" +
               "\(indent)After each loop:\n" +
               "\(afterExpression.describe(indentation + 4))\n" +
               "\(indent)Body:\n" +
               "\(body.describe(indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await initExpression.visit(visitor)
            await condition.visit(visitor)
            await afterExpression.visit(visitor)
            await body.visit(visitor)
        }
    }
}
