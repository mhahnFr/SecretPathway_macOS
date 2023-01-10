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

/// This struct represents a `Codable` color.
struct JSONColor: Codable {
    /// The red part of the color, in the range of `0` - `255`.
    var red: Int
    /// The green part of the color, in the range of `0` - `255`.
    var green: Int
    /// The blue part of the color, in the range of `0` - `255`.
    var blue: Int
    
    /// A native representation of this color.
    var native: NSColor {
        NSColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    /// Initializes this color using the given values.
    ///
    /// - Parameter red: The red part of the color, in the range of `0` - `255`.
    /// - Parameter green: The green part of the color, in the range of `0` - `255`.
    /// - Parameter blue: The blue part of the color, in the range of `0` - `255`.
    init(red: Int, green: Int, blue: Int) {
        self.red   = red
        self.green = green
        self.blue  = blue
    }
    
    /// Initializes this color from the given `NSColor`.
    ///
    /// - Parameter color: The color, it might need to be converted using `usingColorSpace(_:)`.
    init(from color: NSColor) {
        self.init(red: Int(color.redComponent * 255), green: Int(color.greenComponent * 255), blue: Int(color.blueComponent * 255))
    }
}
