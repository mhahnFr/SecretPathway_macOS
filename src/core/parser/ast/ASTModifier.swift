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

/// This class represents a modifier as an AST node.
class ASTModifier: ASTExpression {
    /// The represented modifier.
    let modifier: TokenType?
    
    /// Constructs this AST node using the given token.
    ///
    /// - Parameter token: The token to be represented by this AST node.
    init(token: Token) {
        self.modifier = token.type
        
        super.init(begin: token.begin, end: token.end, type: .MODIFIER)
    }
    
    /// Constructs this AST node using the given bounds.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    init(begin: Int, end: Int) {
        self.modifier = nil
        
        super.init(begin: begin, end: end, type: .MODIFIER)
    }
    
    override func describe(_ indentation: Int) -> String {
        super.describe(indentation) + " \(modifier?.rawValue ?? "<Missing>")"
    }
}
