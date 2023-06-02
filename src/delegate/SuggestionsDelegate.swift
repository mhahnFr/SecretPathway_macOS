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

import Foundation

/// This class represents the delegate for the suggestions window.
class SuggestionsDelegate: ObservableObject {
    /// The available suggestions.
    @Published private(set) var suggestions = [any Suggestion]()
    /// The currently selected suggestion.
    @Published private(set) var selected: (any Suggestion)? {
        willSet {
            if let newValue {
                sh = newValue.hashValue
            } else {
                sh = 0
            }
        }
    }
    /// The hash value of the selected suggestion.
    ///
    /// Set before the selected suggestions is updated.
    private(set) var sh = 0
    
    /// The index of the currently selected suggestion.
    private var index = 0
    private var changed = false
    
    /// Initializes this delegate using the given sugestions.
    ///
    /// - Parameter suggestions: The suggestions initially available.
    init(suggestions: [any Suggestion] = []) {
        self.suggestions = suggestions
    }
    
    /// Selects the next logical suggestion.
    func selectNext() {
        guard !suggestions.isEmpty else { return }
        
        changed = true
        
        let newIndex: Int
        if index + 1 < suggestions.count {
            newIndex = index + 1
        } else {
            newIndex = 0
        }
        select(index: newIndex)
    }
    
    /// Selects the previous logical suggestion.
    func selectPrevious() {
        guard !suggestions.isEmpty else { return }
        
        changed = true
        
        let newIndex: Int
        if index - 1 < 0 {
            newIndex = suggestions.count - 1
        } else {
            newIndex = index - 1
        }
        select(index: newIndex)
    }
    
    /// Updates the available suggestions.
    ///
    /// - Parameter suggestions: The available suggestions.
    func updateSuggestions(with suggestions: [any Suggestion]) {
        // TODO: Make efficient
        self.suggestions = suggestions
        if suggestions.isEmpty {
            index    = 0
            selected = nil
        } else if let selected {
            select(index: suggestions.firstIndex { $0.hashValue == selected.hashValue } ?? 0)
        }
    }
    
    /// Selects the suggestion at the given index.
    ///
    /// Does not check for index bounds.
    ///
    /// - Parameter index: The new index.
    private func select(index: Int) {
        self.index = index
        selected   = suggestions[index]
    }
    
    /// This function should be called before the actual suggestions window will show.
    func windowWillShow() {
        changed = false
        if !suggestions.isEmpty {
            select(index: 0)
        }
    }
}
