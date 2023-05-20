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

/// This structure collects the possible modifiers of a definition.
struct Modifier {
    /// Indicates the access is public.
    var isPublic: Bool
    /// Indicates the access is private.
    var isPrivate: Bool
    /// Indicates the access is protected.
    var isProtected: Bool
    /// Indicates the definition is nosave.
    var isNosave: Bool
    /// Indicates the definition is deprecated.
    var isDeprecated: Bool
    /// Indicated the definition is overritten.
    var isOverride: Bool
    
    /// Initializes this structure using the given values.
    ///
    /// - Parameters:
    ///   - isPublic: Indicates public access.
    ///   - isPrivate: Indicates private access.
    ///   - isProtected: Indicates protected access.
    ///   - isNosave: Indicates nosave.
    ///   - isDeprecated: Indicates deprecation.
    ///   - isOverride: Indicates overriding.
    init(isPublic:     Bool = false,
         isPrivate:    Bool = false,
         isProtected:  Bool = false,
         isNosave:     Bool = false,
         isDeprecated: Bool = false,
         isOverride:   Bool = false) {
        self.isPublic     = isPublic
        self.isPrivate    = isPrivate
        self.isProtected  = isProtected
        self.isNosave     = isNosave
        self.isDeprecated = isDeprecated
        self.isOverride   = isOverride
    }
}
