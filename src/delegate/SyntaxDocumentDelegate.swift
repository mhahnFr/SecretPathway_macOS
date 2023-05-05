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

import AppKit

class SyntaxDocumentDelegate: NSObject, NSTextStorageDelegate {
    internal func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        
        if editedRange.length == 0 { /* TODO: Handle deletions */ }
        
        let str = textStorage.attributedSubstring(from: editedRange).string
        let underlying = textStorage.string
        switch str {
        case "\t": textStorage.replaceCharacters(in: editedRange, with: "    ")
            
        case "(", "{", "[", "\"", "'":
            if isSpecial(underlying, editedRange.location + editedRange.length) {
                textStorage.insert(NSAttributedString(string: getClosingString(str)), at: editedRange.location + editedRange.length)
                // TODO: Ignore addition, move cursor
            }
        case "!":
            if editedRange.location >= 2,
               underlying[underlying.index(underlying.startIndex, offsetBy: editedRange.location - 2) ..< underlying.index(underlying.startIndex, offsetBy: editedRange.location)] == "/*",
               isWhitespace(underlying, editedRange.location + editedRange.length) {
                textStorage.insert(NSAttributedString(string: "!*/"), at: editedRange.location + editedRange.length)
                // TODO: move cursor
            }
            
        case "}":
            if isOnlyWhitespacesOnLine(underlying, editedRange.location) {
                let lineBegin = getLineBegin(underlying, editedRange.location)
                let len = min(editedRange.location - lineBegin, 4)
                textStorage.replaceCharacters(in: NSMakeRange(editedRange.location - len, len), with: "")
                // TODO: move cursor
            }
            
        default: break
        }
    }
    
    private func isOnlyWhitespacesOnLine(_ line: String, _ index: Int) -> Bool {
        let lineBegin = getLineBegin(line, index)
        return isSpaces(String(line[line.index(line.startIndex, offsetBy: lineBegin) ..< line.index(line.startIndex, offsetBy: index)]))
    }
    
    private func isSpaces(_ string: String) -> Bool {
        for c in string.unicodeScalars {
            guard c == " " else { return false }
        }
        return true
    }
    
    private func getLineBegin(_ line: String, _ index: Int) -> Int {
        var lineBegin = index > 0 ? index - 1 : 0
        while !line[line.index(line.startIndex, offsetBy: lineBegin)].isNewline {
            lineBegin -= 1
        }
        return lineBegin > 0 ? lineBegin + 1 : 0
    }
    
    private func isWhitespace(_ string: String, _ location: Int) -> Bool {
        guard location > 0,
              location < string.count else { return true }
        
        return string[string.index(string.startIndex, offsetBy: location)].isWhitespace
    }
    
    private func isSpecial(_ string: String, _ location: Int) -> Bool {
        guard location > 0,
              location < string.count else { return true }
        
        return Tokenizer.isSpecial(string[string.index(string.startIndex, offsetBy: location)])
    }
    
    private func getClosingString(_ opening: String) -> String {
        let toReturn: String
        
        switch opening {
        case "(": toReturn = ")"
        case "{": toReturn = "}"
        case "[": toReturn = "]"
            
        default:  toReturn = opening
        }
        
        return toReturn
    }
}
