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

/// This class represents a declared function parameter
/// as an AST node.
class ASTParameter: ASTExpression {
    /// The declared type of this parameter.
    let type: ASTExpression
    /// The declared name of this parameter.
    let name: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter type: The declared type.
    /// - Parameter name: The declared name.
    init(type: ASTExpression,
         name: ASTExpression) {
        self.type = type
        self.name = name
        
        super.init(begin: type.begin, end: name.end, type: .PARAMETER)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) type:\n"               +
        "\(type.describe(indentation + 4))\n"                  +
        "\(String(repeating: " ", count: indentation))name:\n" +
        name.describe(indentation + 4)
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            type.visit(visitor)
            name.visit(visitor)
        }
    }
}
