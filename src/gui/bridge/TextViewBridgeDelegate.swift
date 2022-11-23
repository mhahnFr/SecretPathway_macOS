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

/// This class protocol defines the necessary functionality that needs to
/// be provided.
protocol TextViewBridgeDelegate: AnyObject {
    /// Called when the SwiftUI updates the bridged text view.
    ///
    /// - Parameter textView: The underlying text view that should be updated.
    func updateTextView(_ textView: NSTextView)
    
    /// Called when the SwiftUI initializes the bridged text view.
    ///
    /// The given text view is already created and can be customized by this
    /// method.
    ///
    /// - Parameter textView: The underlying text view that should be initialized.
    func initTextView(_ textView: NSTextView)
}
