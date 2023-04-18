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

/// This class represents a return statement as an AST node.
class ASTReturn: ASTExpression {
    /// The returned expression.
    let returned: ASTExpression?
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter returned: The returned expression.
    /// - Parameter end: The end position.
    init(begin:    Int,
         returned: ASTExpression?,
         end:      Int) {
        self.returned = returned
        
        super.init(begin: begin, end: end, type: .AST_RETURN)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation))\n\(returned?.describe(indentation + 4) ?? String(repeating: " ", count: indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self), let returned {
            returned.visit(visitor)
        }
    }
}
