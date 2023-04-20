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

/// This class acts as a highlight in a text.
class Highlight {
    /// The beginning position of this highlight.
    let begin: Int
    /// The end position of this highlight.
    let end: Int
    /// The type of the highlight.
    let type: HighlightType
    
    /// Constructs this highlight using the provided information.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - end: The end position.
    ///   - type: The type of the highlight.
    init(begin: Int, end: Int, type: HighlightType) {
        self.begin = begin
        self.end   = end
        self.type  = type
    }
}
