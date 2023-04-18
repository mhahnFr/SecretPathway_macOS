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

/// This class represents a mapping expression as an AST node.
class ASTMapping: ASTExpression {
    /// The content expressions.
    let content: [ASTExpression]
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter content: The content expressions.
    init(begin:   Int,
         end:     Int,
         content: [ASTExpression]) {
        self.content = content
        
        super.init(begin: begin, end: end, type: .AST_MAPPING)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) [\n"
        
        content.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        return "\(buffer)\(String(repeating: " ", count: indentation))]"
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            content.forEach { $0.visit(visitor) }
        }
    }
}
