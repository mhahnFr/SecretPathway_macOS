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

/// This class represents a `case` statement as an AST node.
class ASTCase: ASTExpression {
    /// The actual `case` expression.
    let caseStatement: ASTExpression
    /// The associated expressions.
    let expressions: [ASTExpression]
    
    /// Constructs this AST node using the given sub statements.
    ///
    /// - Parameter caseStatement: The actual `case` expression.
    /// - Parameter expressions: The associated expressions.
    init(caseStatement: ASTExpression, expressions: [ASTExpression]) {
        self.caseStatement = caseStatement
        self.expressions   = expressions
        
        super.init(begin: caseStatement.begin, end: expressions.last?.end ?? caseStatement.end, type: .AST_CASE)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = super.describe(indentation) + " Case:\n"                     +
                     caseStatement.describe(indentation + 4) + "\n"               +
                     String(repeating: " ", count: indentation) + "Statements:\n"
        
        expressions.forEach { buffer.append($0.describe(indentation + 4) + "\n") }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            for expression in expressions { await expression.visit(visitor) }
        }
    }
}
