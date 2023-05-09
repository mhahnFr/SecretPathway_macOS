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

/// This protocol defines how the user can be showered with suggestions.
protocol SuggestionShower: AnyObject {
    /// Called when the suggestions should be updated.
    func updateSuggestions()
    
    /// Called when the suggestion context has been computed.
    ///
    /// - Parameters:
    ///   - type: The type of suggestions to be shown.
    ///   - expected: The expected return type.
    func updateSuggestionContext(type: SuggestionType, expected: TypeProto)
    
    /// Called when the shower of suggestions should start.
    func beginSuggestions()
    
    /// Called when suggestions for super sends should be shown.
    func beginSuperSuggestions()
    
    /// Called when the shower should be turned off.
    func endSuggestions()
}
