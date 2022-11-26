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
    var native: [NSAttributedString.Key: Any]? {
        return [.foregroundColor: NSColor.textColor]
    }
    
    // TODO: Actual attributes
    
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
