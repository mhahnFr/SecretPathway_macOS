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

/// Represents a value returning `return` suggestion.
struct ValueReturnSuggestion: Suggestion {
    let suggestion: String
    let rightSide = "statement"
    
    let relativeCursorPosition: Int
    
    /// Initialies this suggestion using the given value to be returned.
    ///
    /// - Parameter value: The value returned by this suggestion.
    init(value: Any?) {
        self.suggestion = "return \(value ?? "");"
        
        self.relativeCursorPosition = value == nil ? 7 : -1
    }
    
    /// Initializes this suggestion without a returned value.
    init() {
        self.init(value: nil)
    }
}
