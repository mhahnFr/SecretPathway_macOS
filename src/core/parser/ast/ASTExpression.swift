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

/// This class is the base for all expressions.
class ASTExpression {
    /// The beginning position of this expression.
    let begin: Int
    /// The end position of this expression.
    let end: Int
    /// The actual type of this expression.
    let type: ASTType
    
    /// Initializes this AST node using the given beginning and ending position
    /// and its type.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter type: The type.
    init(begin: Int, end: Int, type: ASTType) {
        self.begin = begin
        self.end = end
        self.type = type
    }
}
