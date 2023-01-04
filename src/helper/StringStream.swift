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

struct StringStream {
    private let characters: Array<Character>

    private(set) var index = 0
    
    init(text: any StringProtocol) {
        self.characters = Array(text)
    }
    
    var hasNext: Bool { index < characters.endIndex }
    
    func peek(_ c: Character) -> Bool {
        characters[index] == c
    }
    
    func peek(_ string: any StringProtocol) -> Bool {
        if characters.count - index < string.count { return false }
        
        return String(characters[index ..< string.count]) == string
    }
    
    mutating func skip(_ amount: Int = 1) -> Int {
        var tmpAmount = amount
        if characters.count - index <= amount {
            tmpAmount = characters.count - index
        }
        index += tmpAmount
        return index
    }
    
    mutating func next() -> Character {
        let toReturn = characters[index]
        index += 1
        return toReturn
    }
}
