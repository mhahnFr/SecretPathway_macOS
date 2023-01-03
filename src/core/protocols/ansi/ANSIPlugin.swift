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

import AppKit
import Foundation

/// This class acts as a plugin for ANSI escape codes.
class ANSIPlugin: ProtocolPlugin {
    /// The buffer for the incoming escape code.
    private var buffer = Data()
    
    /// The owner of this plugin, used for altering the text styles.
    private unowned(unsafe) let owner: ConnectionDelegate
    
    /// Initializes this plugin using the given owner.
    ///
    /// - Parameter owner: The owner of this plugin.
    init(_ owner: ConnectionDelegate) {
        self.owner = owner
    }
    
    internal func isBegin(byte: UInt8) -> Bool {
        return byte == 0x1B
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        if byte == 0x6D {
            _ = parseBuffer()
            buffer = Data()
            return false
        }
        buffer.append(byte)
        return true
    }
    
    /// Tries to decode the given number to a colour using the default 256 bit
    /// colour table.
    ///
    /// The number must be in the range of `0` to `255` in order to succeed.
    /// Otherwise, `nil` is returned.
    ///
    /// - Parameter colorCode: The colour code to be decoded.
    /// - Returns: The decoded colour or `nil` if it was not possible.
    private func colorFrom256Bit(_ colorCode: Int) -> NSColor? {
        let result: NSColor?
        
        if colorCode < 16 {
            switch colorCode {
            case 0:  result = NSColor(red: 0,    green: 0,    blue: 0,    alpha: 1)
            case 1:  result = NSColor(red: 0.75, green: 0,    blue: 0,    alpha: 1)
            case 2:  result = NSColor(red: 0,    green: 0.75, blue: 0,    alpha: 1)
            case 3:  result = NSColor(red: 0.75, green: 0.75, blue: 0,    alpha: 1)
            case 4:  result = NSColor(red: 0,    green: 0,    blue: 0.75, alpha: 1)
            case 5:  result = NSColor(red: 0.75, green: 0,    blue: 0.75, alpha: 1)
            case 6:  result = NSColor(red: 0,    green: 0.75, blue: 0.75, alpha: 1)
            case 7:  result = NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
            case 8:  result = NSColor(red: 0.5,  green: 0.5,  blue: 0.5,  alpha: 1)
            case 9:  result = NSColor(red: 1,    green: 0,    blue: 0,    alpha: 1)
            case 10: result = NSColor(red: 0,    green: 1,    blue: 0,    alpha: 1)
            case 11: result = NSColor(red: 1,    green: 1,    blue: 0,    alpha: 1)
            case 12: result = NSColor(red: 0,    green: 0,    blue: 1,    alpha: 1)
            case 13: result = NSColor(red: 1,    green: 0,    blue: 1,    alpha: 1)
            case 14: result = NSColor(red: 0,    green: 1,    blue: 1,    alpha: 1)
            case 15: result = NSColor(red: 1,    green: 1,    blue: 1,    alpha: 1)
            default: result = nil
            }
        } else if colorCode < 232 {
            let cubeCalc: (Int, Int) -> CGFloat = { color, code in
                let tmp = ((color - 16) / code) % 6
                return CGFloat(tmp == 0 ? 0 :
                    (14135 + 10280 * tmp) / 256)
            }
            result = NSColor(red: cubeCalc(colorCode, 36) / 255, green: cubeCalc(colorCode, 6) / 255, blue: cubeCalc(colorCode, 1) / 255, alpha: 1)
        } else if colorCode < 256 {
            let value = CGFloat((2056 + 2570 * (colorCode - 232)) / 256) / 255
            result = NSColor(red: value, green: value, blue: value, alpha: 1)
        } else {
            result = nil
        }
        
        return result
    }
    
    /// Parses the buffer into the current style.
    ///
    /// If it is impossible, `false` is returned and the current style remains the same as before
    /// invocation of this function.
    ///
    /// - Returns: Whether the ANSI code was successfully parsed.
    private func parseBuffer() -> Bool {
        guard let string = String(data: buffer, encoding: .ascii) else { return false }
        
        let before = owner.currentStyle
        
        let sub = string[string.index(after: string.startIndex)...]
        let splits = sub.split(separator: ";", omittingEmptySubsequences: true)
        var i = 0
        while i < splits.endIndex {
            let split = splits[i]
            
            if let decoded = Int(split) {
                switch decoded {
                case 0:  owner.currentStyle            = SPStyle()
                case 1:  owner.currentStyle.bold       = true
                case 3:  owner.currentStyle.italic     = true
                case 4:  owner.currentStyle.underlined = true
                case 21: owner.currentStyle.bold       = false
                case 23: owner.currentStyle.italic     = false
                case 24: owner.currentStyle.underlined = false
                    
                // Foreground
                case 30: owner.currentStyle.foreground = .black
                case 31: owner.currentStyle.foreground = NSColor(red: 0.75, green: 0,    blue: 0,    alpha: 1)
                case 32: owner.currentStyle.foreground = NSColor(red: 0,    green: 0.75, blue: 0,    alpha: 1)
                case 33: owner.currentStyle.foreground = NSColor(red: 0.75, green: 0.75, blue: 0,    alpha: 1)
                case 34: owner.currentStyle.foreground = NSColor(red: 0,    green: 0,    blue: 0.75, alpha: 1)
                case 35: owner.currentStyle.foreground = NSColor(red: 0.75, green: 0,    blue: 0.75, alpha: 1)
                case 36: owner.currentStyle.foreground = NSColor(red: 0,    green: 0.75, blue: 0.75, alpha: 1)
                case 37: owner.currentStyle.foreground = .lightGray
                case 39: owner.currentStyle.foreground = .textColor
                case 90: owner.currentStyle.foreground = .darkGray
                case 91: owner.currentStyle.foreground = NSColor(red: 1,    green: 0,    blue: 0,    alpha: 1)
                case 92: owner.currentStyle.foreground = NSColor(red: 0,    green: 1,    blue: 0,    alpha: 1)
                case 93: owner.currentStyle.foreground = NSColor(red: 1,    green: 1,    blue: 0,    alpha: 1)
                case 94: owner.currentStyle.foreground = NSColor(red: 0,    green: 0,    blue: 1,    alpha: 1)
                case 95: owner.currentStyle.foreground = NSColor(red: 1,    green: 0,    blue: 1,    alpha: 1)
                case 96: owner.currentStyle.foreground = NSColor(red: 0,    green: 1,    blue: 1,    alpha: 1)
                case 97: owner.currentStyle.foreground = .white
                    
                // Background
                case 40:  owner.currentStyle.background = .black
                case 41:  owner.currentStyle.background = NSColor(red: 0.75, green: 0,    blue: 0,    alpha: 1)
                case 42:  owner.currentStyle.background = NSColor(red: 0,    green: 0.75, blue: 0,    alpha: 1)
                case 43:  owner.currentStyle.background = NSColor(red: 0.75, green: 0.75, blue: 0,    alpha: 1)
                case 44:  owner.currentStyle.background = NSColor(red: 0,    green: 0,    blue: 0.75, alpha: 1)
                case 45:  owner.currentStyle.background = NSColor(red: 0.75, green: 0,    blue: 0.75, alpha: 1)
                case 46:  owner.currentStyle.background = NSColor(red: 0,    green: 0.75, blue: 0.75, alpha: 1)
                case 47:  owner.currentStyle.background = .lightGray
                case 49:  owner.currentStyle.background = .textBackgroundColor
                case 100: owner.currentStyle.background = .darkGray
                case 101: owner.currentStyle.background = NSColor(red: 1,    green: 0,    blue: 0,    alpha: 1)
                case 102: owner.currentStyle.background = NSColor(red: 0,    green: 1,    blue: 0,    alpha: 1)
                case 103: owner.currentStyle.background = NSColor(red: 1,    green: 1,    blue: 0,    alpha: 1)
                case 104: owner.currentStyle.background = NSColor(red: 0,    green: 0,    blue: 1,    alpha: 1)
                case 105: owner.currentStyle.background = NSColor(red: 1,    green: 0,    blue: 1,    alpha: 1)
                case 106: owner.currentStyle.background = NSColor(red: 0,    green: 1,    blue: 1,    alpha: 1)
                case 107: owner.currentStyle.background = .white
                  
                case 38:
                    if i + 1 >= splits.endIndex { break }
                    
                    i += 1
                    if let code = Int(splits[i]) {
                        if (code == 5 && i + 1 >= splits.endIndex) || (code == 2 && i + 3 >= splits.endIndex) { break }
                        if code == 5, let colorCode = Int(splits[i + 1]) {
                            owner.currentStyle.foreground = colorFrom256Bit(colorCode)
                            i += 1
                        } else if code == 2, let red = Int(splits[i + 1]), let green = Int(splits[i + 2]), let blue = Int(splits[i + 3]) {
                            owner.currentStyle.foreground = NSColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
                            i += 3
                        }
                    }
                    
                case 48:
                    if i + 1 >= splits.endIndex { break }
                    
                    i += 1
                    if let code = Int(splits[i]) {
                        if (code == 5 && i + 1 >= splits.endIndex) || (code == 2 && i + 3 >= splits.endIndex) { break }
                        if code == 5, let colorCode = Int(splits[i + 1]) {
                            owner.currentStyle.background = colorFrom256Bit(colorCode)
                            i += 1
                        } else if code == 2, let red = Int(splits[i + 1]), let green = Int(splits[i + 2]), let blue = Int(splits[i + 3]) {
                            owner.currentStyle.background = NSColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
                            i += 3
                        }
                    }
                    
                default: print("Code not supported: \(decoded)!")
                }
            } else {
                owner.currentStyle = before
                return false
            }
            i += 1
        }
        return true

    }
}
