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

/// This enumeration contains all possible suggestion types.
enum SuggestionType {
    /// Represents a literal value, no suggestions.
    case literal
    /// Represents anything, all kinds of suggestions.
    case any
    /// Rerpresents identifiers and literal values.
    case literalIdentifier
    /// Represents identifiers.
    case identifier
    /// Represents types.
    case type
    /// Represents modifiers.
    case modifier
    /// Represents modifiers and types.
    case typeModifier
    
    /// Returns whether this suggestion type is one of the given types.
    ///
    /// - Parameter types: The other types.
    /// - Returns: Whether this type is one of the given ones.
    func isType(_ types: Self...) -> Bool {
        types.contains(self)
    }
}
