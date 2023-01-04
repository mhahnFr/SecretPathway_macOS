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

/// This struct represents a string character stream.
struct StringStream {
    /// The underlying character array.
    private let characters: Array<Character>

    /// The current index of the stream.
    private(set) var index = 0
    
    /// Indicates whether the stream has a next character to be read.
    var hasNext: Bool { index < characters.endIndex }

    /// Initializes this stream using the given string.
    ///
    /// - Parameter text: The string to construct the stream from.
    init(text: any StringProtocol) {
        self.characters = Array(text)
    }
    
    /// Returns whether the given character equals the next
    /// character to be read.
    ///
    /// - Parameter c: The character to be checked.
    /// - Returns: Whether the next character to be read equals the given one.
    func peek(_ c: Character) -> Bool {
        characters[index] == c
    }
    
    /// Returns whether the given string equals to the next characters
    /// to be read.
    ///
    /// - Parameter string: The string to be checked.
    /// - Returns: Whether the next characters to be read form the given string
    func peek(_ string: any StringProtocol) -> Bool {
        if characters.count - index < string.count { return false }
        
        return String(characters[index ..< string.count]) == string
    }
    
    /// Skips the given amount of characters.
    ///
    /// If there are less characters left in the stream than the amount that
    /// should be skipped, all remaining characters are skipped. Returns
    /// the new index.
    ///
    /// - Parameter amount: The amount of characters to be skipped.
    /// - Returns: The new index after the skipping.
    mutating func skip(_ amount: Int = 1) -> Int {
        var tmpAmount = amount
        if characters.count - index <= amount {
            tmpAmount = characters.count - index
        }
        index += tmpAmount
        return index
    }
    
    /// Advances this stream to the next character.
    ///
    /// The read character is returned.
    ///
    /// - Returns: The next character in the stream.
    mutating func next() -> Character {
        let toReturn = characters[index]
        index += 1
        return toReturn
    }
}
