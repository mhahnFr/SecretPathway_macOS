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

/// This class represents a subscript expression as an AST node.
class ASTSubscript: ASTExpression {
    /// The underlying expression.
    let expression: ASTExpression
    
    /// Constructs this AST node using the given expression.
    ///
    /// - Parameter expression: The expression to be represented as a subscript.
    init(expression: ASTExpression) {
        self.expression = expression
        
        super.init(begin: expression.begin, end: expression.end, type: .SUBSCRIPT, subNodes: [expression])
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation))\n\(expression.describe(indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await expression.visit(visitor)
        }
    }
}
