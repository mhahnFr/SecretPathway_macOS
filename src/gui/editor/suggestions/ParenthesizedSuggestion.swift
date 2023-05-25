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

/// Represents a parenthesized suggestion.
struct ParenthesizedSuggestion: Suggestion {
    let suggestion: String
    let description: String
    let rightSide = "statement"
    
    let relativeCursorPosition: Int
    
    /// Initializes this suggestion using the given token type.
    ///
    /// - Parameter keyword: The keyword to be represented as perenthesized suggestion.
    init(keyword: TokenType) {
        let string = keyword.rawValue.lowercased()
        
        self.suggestion  = "\(string) ()"
        self.description = "\(string)"
        
        self.relativeCursorPosition = string.count + 2
    }
}
