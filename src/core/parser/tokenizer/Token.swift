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
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
 */

/// Represents a token.
struct Token: Equatable {
    /// The beginning of this token in the stream.
    let begin: Int
    /// The type of this token.
    let type: TokenType
    /// The optional payload of this token.
    let payload: Any?
    /// The end of this token in the stream.
    let end: Int
    
    /// Initializes this token using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter type: The type of this token.
    /// - Parameter payload: The optional payload.
    /// - Parameter end: The end position.
    init(begin: Int, type: TokenType, payload: Any? = nil, end: Int) {
        self.begin   = begin
        self.type    = type
        self.payload = payload
        self.end     = end
    }
    
    /// Returns whether this token is of the given type.
    ///
    /// - Parameter type: The type to be checked.
    /// - Returns: Whether the type equals to the given one.
    func isType(_ type: TokenType) -> Bool {
        self.type == type
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.begin == rhs.begin &&
        lhs.end   == rhs.end   &&
        lhs.type  == rhs.type
    }
}
