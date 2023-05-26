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

/// This class represents a scope chain as an AST node.
class ASTScopeChain: ASTExpression {
    /// The name expressions of this scope chain.
    let names: [ASTExpression]
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - end: The end position.
    ///   - names: The name expressions.
    init(begin: Int, end: Int, names: [ASTExpression]) {
        self.names = names
        
        super.init(begin: begin, end: end, type: .SCOPE_CHAIN, subNodes: names)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) Names:\n"
        
        names.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            for name in names {
                await name.visit(visitor)
            }
        }
    }
}
