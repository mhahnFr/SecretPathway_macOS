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

struct JSONColor: Codable {
    var red: Int
    var green: Int
    var blue: Int
    
    var native: NSColor {
        NSColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    init(red: Int, green: Int, blue: Int) {
        self.red   = red
        self.green = green
        self.blue  = blue
    }
    
    init(from color: NSColor) {
        self.init(red: Int(color.redComponent * 255), green: Int(color.greenComponent * 255), blue: Int(color.blueComponent * 255))
    }
}
