/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022 - 2023  mhahnFr
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

import Foundation

/// This protocol defines functionalitiy a connection sender has to conform to.
protocol ConnectionSender: AnyObject {
    /// Indicates whether to escape the telnet's `IAC` command.
    var escapeIAC: Bool { get set }
    /// The charset to be used for encoding strings.
    var charset: String.Encoding { get set }
    /// Indicates whether to hide user input.
    var passwordMode: Bool { get set }
    /// The prompt text to be displayed next to the input field.
    var prompt: String? { get set }
    
    /// This function is called when a piece of data should be sent.
    ///
    /// - Parameter data: The data that should be sent.
    func send(data: Data)
    
    /// This function is called when the SPP should be activated.
    func enableSPP()
    
    /// This function is called when an editor should be opened.
    ///
    /// The file given should be displayed by the editor.
    ///
    /// - Parameter file: The file to be opened.
    func openEditor(_ file: String?)
}
