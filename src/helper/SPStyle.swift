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

/// Represents a indepent represantation of a text style.
struct SPStyle {
    /// The native representation of this style.
    var native: [NSAttributedString.Key: Any] {
        var toReturn: [NSAttributedString.Key: Any] = [:]
        
        if let foreground {
            toReturn[.foregroundColor] = foreground
        }
        if let background {
            toReturn[.backgroundColor] = background
        }
        if let italic {
            if italic {
                NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            } else {
                NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
            }
        }
        if let bold {
            if bold {
                NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            } else {
                NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
            }
        }
        if let underlined {
            toReturn[.underlineStyle] = underlined ? NSUnderlineStyle.thick : NSUnderlineStyle.init()
        }
        if let striken {
            toReturn[.strikethroughStyle] = striken ? NSUnderlineStyle.thick : NSUnderlineStyle.init()
        }
        toReturn[.font] = font

        return toReturn
    }
    
    var bold: Bool?
    var italic: Bool?
    var striken: Bool?
    var underlined: Bool?
    var foreground: NSColor? = .textColor
    var background: NSColor?
    var font: NSFont = .monospacedSystemFont(ofSize: Settings.shared.fontSize, weight: .regular)
    
    /// Initializes this style with default values.
    init() {}
    
    /// Initializes this style using the two given ones.
    ///
    /// It is based on the first style and altered by the other style.
    ///
    /// - Parameter style: The base style.
    /// - Parameter otherStyle: The style used to alter the given attributes.
    init(from style: SPStyle, alteredBy otherStyle: SPStyle) {
        // TODO: Create altered style
    }
}
