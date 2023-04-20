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

/// This class represents a highlight with an associated message.
class MessagedHighlight: Highlight {
    /// The associated message.
    let message: String
    
    /// Initializes this highlight with the required information.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - end: The end position.
    ///   - type: The type of the highlight.
    ///   - message: The associated message.
    init(begin:   Int,
         end:     Int,
         type:    HighlightType,
         message: String) {
        self.message = message
        
        super.init(begin: begin, end: end, type: type)
    }
}
