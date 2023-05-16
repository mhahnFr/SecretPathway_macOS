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

/// This class holds some constants used in the whole project.
class Constants {
    /// The name of the app that should be used when displayed.
    static let APP_NAME       = "SecretPathway"
    /// The version as string.
    static let VERSION_STRING = "1.0"
    
    /// Constants to be used for stored settings.
    class Storage {
        /// The size of the font.
        static let FONT_SIZE               = "\(APP_NAME).fontSize"
        /// The currently open connections.
        static let OPEN_CONNECTIONS        = "\(APP_NAME).openConnections"
        /// The recently opened connections.
        static let RECENT_CONNECTIONS      = "\(APP_NAME).recentConnections"
        /// The key for storing whether to use UTF-8 by default.
        static let USE_UTF8                = "\(APP_NAME).useUTF8"
        /// Indicates whether to display the editor in its controlling connection window.
        static let EDITOR_INLINED          = "\(APP_NAME).editorInlined"
        /// Indicates whether to enable the syntax highlighting in the LPC editor by default.
        static let EDITOR_SYNTAX_HIGHLIGHT = "\(APP_NAME).editorSyntaxHighlighting"
        /// The used editor theme.
        static let EDITOR_THEME            = "\(APP_NAME).editorTheme"
        /// The editor's window's X-coordinate.
        static let EDITOR_WINDOW_X         = "\(APP_NAME).editorWindowX"
        /// The editor's window's Y-coordinate.
        static let EDITOR_WINDOW_Y         = "\(APP_NAME).editorWindowY"
        /// The editor's window's width.
        static let EDITOR_WIDTH            = "\(APP_NAME).editorWidth"
        /// The editor's window's height.
        static let EDITOR_HEIGHT           = "\(APP_NAME).editorHeight"
    }
}
