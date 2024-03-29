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

/// This class represents a wrong token as an AST node.
class ASTWrong: ASTHole {
    /// Initializes this AST node using the represented token and
    /// the error message.
    ///
    /// - Parameter token: The token to be represented.
    /// - Parameter message: The reasoning message.
    init(token: Token, message: String, expected: HighlightType?) {
        super.init(begin: token.begin, end: token.end, message: message, type: .WRONG, expected: expected)
    }
    
    override func describe(_ indentation: Int) -> String {
        super.describe(indentation) + " " + message
    }
}
