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

/// This class represents a cast expression as an AST node.
class ASTCast: ASTExpression {
    /// The type to which to be casted.
    let castType: ASTExpression
    /// The casted expression.
    let castExpression: ASTExpression
    
    /// Initializes this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter castType: The type to which to cast to.
    /// - Parameter castExpression: The casted expression.
    init(begin: Int, castType: ASTExpression, castExpression: ASTExpression) {
        self.castType       = castType
        self.castExpression = castExpression
        
        super.init(begin:    begin,
                   end:      castExpression.end,
                   type:     .CAST,
                   subNodes: [castType, castExpression])
    }
    
    override func describe(_ indentation: Int) -> String {
        super.describe(indentation)              + "\n" +
        castType.describe(indentation + 4)       + "\n" +
        castExpression.describe(indentation + 4)
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await castType.visit(visitor)
            await castExpression.visit(visitor)
        }
    }
}
