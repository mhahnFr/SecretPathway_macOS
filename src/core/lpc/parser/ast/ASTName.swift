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

/// This class represents a name as an AST node.
class ASTName: ASTExpression {
    /// The represented name.
    let name: String?
    
    /// Constructs this AST node using the name token to be
    /// represented.
    ///
    /// - Parameter token: The name token to be represented.
    init(token: Token) {
        self.name = token.payload as? String
        
        super.init(begin: token.begin, end: token.end, type: .NAME)
    }
    
    /// Constructs this AST node using the given bounds.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    init(begin: Int, end: Int) {
        name = nil
        
        super.init(begin: begin, end: end, type: .NAME)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) \(name ?? "<missing>")"
    }
}
