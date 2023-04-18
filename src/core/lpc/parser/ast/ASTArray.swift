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

/// This class represents an array statement as an AST node.
class ASTArray: ASTExpression {
    /// The expressions making the content of the array expression.
    let content: [ASTExpression]
    
    /// Initializes this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter content: The expressions defining the content of the array.
    init(begin: Int, end: Int, content: [ASTExpression]) {
        self.content = content
        
        super.init(begin: begin, end: end, type: .ARRAY)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = super.describe(indentation) + " [\n"
        
        for element in content {
            buffer.append(element.describe(indentation + 4) + "\n")
        }
        
        buffer.append(String(repeating: " ", count: indentation) + "]")
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            content.forEach { $0.visit(visitor) }
        }
    }
}
