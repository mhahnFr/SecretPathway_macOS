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

/// This class represents a `foreach` statement as an AST node.
class ASTForEach: ASTExpression {
    /// The variable expression.
    let variable: ASTExpression
    /// The range expression.
    let rangeExpression: ASTExpression
    /// The body.
    let body: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter variable: The variable declaration.
    /// - Parameter rangeExpression: The range expression extracting the variable.
    /// - Parameter body: The body.
    init(begin:           Int,
         variable:        ASTExpression,
         rangeExpression: ASTExpression,
         body:            ASTExpression) {
        self.variable        = variable
        self.rangeExpression = rangeExpression
        self.body            = body
        
        super.init(begin:    begin,
                   end:      body.end,
                   type:     .AST_FOREACH,
                   subNodes: [variable, rangeExpression, body])
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        return "\(super.describe(indentation)) Variable:\n" +
               "\(variable.describe(indentation + 4))\n" +
               "\(indent)Range expression:\n" +
               "\(rangeExpression.describe(indentation + 4))\n" +
               "\(indent)Body:\n" +
               body.describe(indentation)
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await variable.visit(visitor)
            await rangeExpression.visit(visitor)
            await body.visit(visitor)
        }
    }
}
