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

struct JSONStyle: Codable {
    var bold: Bool?
    var italic: Bool?
    var striken: Bool?
    var underlined: Bool?
    var foreground: JSONColor?
    var background: JSONColor?
    
    var native: SPStyle {
        SPStyle(bold: bold, italic: italic, striken: striken, underlined: underlined, foreground: foreground?.native, background: background?.native)
    }
    
    init(bold:       Bool?      = nil,
         italic:     Bool?      = nil,
         striken:    Bool?      = nil,
         underlined: Bool?      = nil,
         foreground: JSONColor? = nil,
         background: JSONColor? = nil) {
        self.bold       = bold
        self.italic     = italic
        self.striken    = striken
        self.underlined = underlined
        self.foreground = foreground
        self.background = background
    }
    
    init(from style: SPStyle) {
        self.bold       = style.bold
        self.italic     = style.italic
        self.striken    = style.striken
        self.underlined = style.underlined
        if let foreground = style.foreground?.usingColorSpace(.genericRGB), style.foreground != .textColor {
            self.foreground = JSONColor(from: foreground)
        }
        if let background = style.background?.usingColorSpace(.genericRGB), style.background != .textBackgroundColor {
            self.background = JSONColor(from: background)
        }
    }
}
