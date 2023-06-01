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

class SuggestionsDelegate: ObservableObject {
    @Published private(set) var suggestions = [any Suggestion]()
    @Published private(set) var selected: (any Suggestion)? {
        willSet {
            if let newValue {
                sh = newValue.hashValue
            } else {
                sh = 0
            }
        }
    }
    private(set) var sh = 0
    
    private var index = 0
    
    init(suggestions: [any Suggestion] = []) {
        self.suggestions = suggestions
    }
    
    func selectNext() {
        guard !suggestions.isEmpty else { return }
        
        let newIndex: Int
        if index + 1 < suggestions.count {
            newIndex = index + 1
        } else {
            newIndex = 0
        }
        select(index: newIndex)
    }
    
    func selectPrevious() {
        guard !suggestions.isEmpty else { return }
        
        let newIndex: Int
        if index - 1 < 0 {
            newIndex = suggestions.count - 1
        } else {
            newIndex = index - 1
        }
        select(index: newIndex)
    }
    
    func updateSuggestions(with suggestions: [any Suggestion]) {
        // TODO: Make efficient
        self.suggestions = suggestions
        if suggestions.isEmpty {
            selected = nil
        }
    }
    
    private func select(index: Int) {
        self.index = index
        selected = suggestions[index]
    }
    
    func windowWillShow() {
        if !suggestions.isEmpty {
            select(index: 0)
        }
    }
}
