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

/// Represents a definition suggestion.
struct DefinitionSuggestion: Suggestion {
    let suggestion:  String
    let description: String
    let rightSide:   String
    /// The type of the suggested definition.
    let type: TypeProto
    
    /// Initializes this suggestion using the given definition.
    ///
    /// - Parameter definition: The definition to be suggested.
    init(definition: Definition) {
        self.type        = definition.returnType
        self.suggestion  = definition.name
        self.description = definition.string
        self.rightSide   = type.string
    }
    
    init(_ other: DefinitionSuggestion, isSuper: Bool) {
        self.type        = other.type
        self.suggestion  = "\(isSuper ? "::" : "")\(other.suggestion)"
        self.description = "\(isSuper ? "::" : "")\(other.description)"
        self.rightSide   = other.rightSide
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(suggestion)
        hasher.combine(description)
        hasher.combine(rightSide)
    }
    
    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
