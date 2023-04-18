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

/// This class represents an operation as an AST node.
class ASTOperation: ASTExpression {
    /// The left hand side expression.
    let lhs: ASTExpression
    /// The right hand side expression.
    let rhs: ASTExpression
    /// The type of the represented operation.
    let operatorType: TokenType
    
    /// Constructs this AST node using the two given sub-expressions.
    ///
    /// - Parameter lhs: The left hand side expression.
    /// - Parameter rhs: The right hand side expression.
    /// - Parameter operatorType: The type of the represented operation.
    init(lhs: ASTExpression, rhs: ASTExpression, operatorType: TokenType) {
        self.lhs          = lhs
        self.rhs          = rhs
        self.operatorType = operatorType
        
        super.init(begin: lhs.begin, end: rhs.end, type: .OPERATION)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation))\n\(lhs.describe(indentation + 4))\n" +
        "\(String(repeating: " ", count: indentation))\(operatorType)\n"     +
        "\(rhs.describe(indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            lhs.visit(visitor)
            rhs.visit(visitor)
        }
    }
}
