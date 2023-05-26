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

/// This class represents a complete switch statement as an AST node.
class ASTSwitch: ASTExpression {
    /// The variable expression.
    let variableExpression: ASTExpression
    /// The cases in this switch statement.
    let cases: [ASTExpression]
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter variableExpression: The variable expression.
    /// - Parameter cases: The cases.
    init(begin:              Int,
         end:                Int,
         variableExpression: ASTExpression,
         cases:              [ASTExpression]) {
        self.variableExpression = variableExpression
        self.cases              = cases
        
        var subs = [variableExpression]
        subs.append(contentsOf: cases)
        super.init(begin: begin, end: end, type: .AST_SWITCH, subNodes: subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) Variable:\n\(variableExpression.describe(indentation + 4))" +
                     "\(String(repeating: " ", count: indentation))Cases:\n"
        
        cases.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await variableExpression.visit(visitor)
            for c in cases { await c.visit(visitor) }
        }
    }
}
