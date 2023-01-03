/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022  mhahnFr
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

/// Represents a indepent representation of a text style.
struct SPStyle: CustomDebugStringConvertible, Equatable {
    var debugDescription: String {
        var toReturn = "SPStyle: [ "
        
        if let bold       { toReturn += "bold: \(bold), "             }
        if let italic     { toReturn += "italic: \(italic), "         }
        if let underlined { toReturn += "underlined: \(underlined), " }
        if let striken    { toReturn += "striken: \(striken), "       }
        if let foreground { toReturn += "foreground: \(foreground == NSColor.textColor           ? "default" : foreground.debugDescription), " }
        if let background { toReturn += "background: \(background == NSColor.textBackgroundColor ? "default" : background.debugDescription)"   }
        
        toReturn += " ]"
        
        return toReturn
    }
    
    /// A style clearing all relevant attributes.
    static let clearing = SPStyle(bold: false, italic: false, striken: false, underlined: false)
    
    /// The native representation of this style.
    var native: [NSAttributedString.Key: Any] {
        var toReturn: [NSAttributedString.Key: Any] = [:]
        var tmpFont = font
        
        if let foreground {
            toReturn[.foregroundColor] = foreground
        }
        if let background {
            toReturn[.backgroundColor] = background
        }
        if let italic {
            if italic {
                tmpFont = NSFontManager.shared.convert(tmpFont, toHaveTrait: .italicFontMask)
            } else {
                tmpFont = NSFontManager.shared.convert(tmpFont, toNotHaveTrait: .italicFontMask)
            }
        }
        if let bold {
            if bold {
                tmpFont = NSFontManager.shared.convert(tmpFont, toHaveTrait: .boldFontMask)
            } else {
                tmpFont = NSFontManager.shared.convert(tmpFont, toNotHaveTrait: .boldFontMask)
            }
        }
        if let underlined {
            toReturn[.underlineStyle] = underlined ? NSUnderlineStyle.single.rawValue : 0
        }
        if let striken {
            toReturn[.strikethroughStyle] = striken ? NSUnderlineStyle.single.rawValue : 0
        }
        toReturn[.font] = tmpFont

        return toReturn
    }
    
    /// Indicates whether to use a bold font.
    var bold: Bool?
    /// Indicates whether to use an italic font.
    var italic: Bool?
    /// Indicates whether to use a strike-through font.
    var striken: Bool?
    /// Indicates whether to use a underlined font.
    var underlined: Bool?
    /// The foreground color to be used.
    var foreground: NSColor?
    /// The background color to be used.
    var background: NSColor?
    /// The font the changes are based on.
    var font: NSFont
    
    /// Initializes this style with default values.
    init(bold: Bool? = nil, italic: Bool? = nil, striken: Bool? = nil, underlined: Bool? = nil,
         foreground: NSColor? = .textColor, background: NSColor? = .textBackgroundColor,
         font: NSFont = .monospacedSystemFont(ofSize: Settings.shared.fontSize, weight: .regular)) {
        self.bold       = bold
        self.italic     = italic
        self.striken    = striken
        self.underlined = underlined
        self.foreground = foreground
        self.background = background
        self.font       = font
    }
    
    /// Initializes this style using the two given ones.
    ///
    /// It is based on the first style and altered by the other style.
    ///
    /// - Parameter style: The base style.
    /// - Parameter otherStyle: The style used to alter the given attributes.
    init(from style: SPStyle, alteredBy otherStyle: SPStyle) {
        self.init(
            bold:       otherStyle.bold       ?? style.bold,
            italic:     otherStyle.italic     ?? style.italic,
            striken:    otherStyle.striken    ?? style.striken,
            underlined: otherStyle.underlined ?? style.underlined,
            foreground: otherStyle.foreground ?? style.foreground,
            background: otherStyle.background ?? style.background,
        
            font: otherStyle.font)
    }
}
