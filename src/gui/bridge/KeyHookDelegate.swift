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

/// This protocol defines the interface for the delegate of the KeyHookTextView.
protocol KeyHookDelegate: AnyObject {
    /// Called when the `keyPressed(with:)` is called.
    ///
    /// Implementors return whether to continue processing the key press.
    ///
    /// - Parameter event: The event the text view got.
    /// - Returns: Whether to pass the event to the native implementation.
    func keyDown(with event: NSEvent) -> Bool
}
