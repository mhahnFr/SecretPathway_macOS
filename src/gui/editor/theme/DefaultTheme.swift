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

/// Represents the default syntax highlighting theme.
struct DefaultTheme: SPTheme {
    /// The mapping with the styles.
    private let styles: [HighlightType: SPStyle]
    
    /// Initializes this theme.
    init() {
        let keyword    = SPStyle(bold: true, foreground: NSColor(red: 0.015, green: 0.388, blue: 0.51, alpha: 1))
        let type       = SPStyle(foreground: NSColor(red: 0.015, green: 0.51,  blue: 0.51,  alpha: 1))
        let control    = SPStyle(foreground: NSColor(red: 0.714, green: 0.004, blue: 0.09,  alpha: 1))
        let id         = SPStyle(foreground: NSColor(red: 0.702, green: 0.043, blue: 0.749, alpha: 1))
        let flow       = SPStyle(foreground: NSColor(red: 0.086, green: 0.459, blue: 0.02,  alpha: 1))
        let comment    = SPStyle(italic: true, foreground: .gray)
        let const      = SPStyle(foreground: NSColor(red: 0.671, green: 0.627, blue: 0.012, alpha: 1))
        let warning    = SPStyle(underlined: true, foreground: NSColor(red: 0.75, green: 0.75, blue: 0, alpha: 1))
        let error      = SPStyle(bold: true, foreground: .red)
        let error2     = SPStyle(underlined: true, foreground: .red)
        let error3     = SPStyle(foreground: .red)
        let missing    = SPStyle(background: NSColor(red: 1, green: 0.5098, blue: 0.5098, alpha: 1))
        let unresolved = SPStyle(bold: true, underlined: true, foreground: NSColor(red: 0.75, green: 0.75, blue: 0, alpha: 1))
        styles = [
            .IDENTIFIER: id,
            
            .NIL:   keyword,
            .TRUE:  keyword,
            .FALSE: keyword,
            
            .INCLUDE:    control,
            .INHERIT:    control,
            .PRIVATE:    control,
            .PROTECTED:  control,
            .PUBLIC:     control,
            .OVERRIDE:   control,
            .DEPRECATED: control,
            .NOSAVE:     control,
            .STATIC:     control,
            .NEW:        control,
            .THIS:       control,
            .SIZEOF:     control,
            .IS:         control,
            .CLASS:      control,
            
            .IF:         flow,
            .ELSE:       flow,
            .WHILE:      flow,
            .DO:         flow,
            .FOR:        flow,
            .FOREACH:    flow,
            .SWITCH:     flow,
            .CASE:       flow,
            .DEFAULT:    flow,
            .BREAK:      flow,
            .CONTINUE:   flow,
            .RETURN:     flow,
            .TRY:        flow,
            .CATCH:      flow,
            
            .VOID:           type,
            .CHAR_KEYWORD:   type,
            .INT_KEYWORD:    type,
            .FLOAT_KEYWORD:  type,
            .BOOL:           type,
            .OBJECT:         type,
            .STRING_KEYWORD: type,
            .SYMBOL_KEYWORD: type,
            .MAPPING:        type,
            .ANY:            type,
            .MIXED:          type,
            .AUTO:           type,
            .OPERATOR:       type,
            .LET:            type,
            .EXCEPTION:      type,
            
            .INTEGER:   const,
            .FLOAT:     const,
            .STRING:    const,
            .CHARACTER: const,
            .SYMBOL:    const,
            
            .COMMENT_LINE:  comment,
            .COMMENT_BLOCK: comment,
            
            .WARNING:           warning,
            .NOT_FOUND_BUILTIN: warning,
            
            .WRONG: error,
            
            .ERROR:         error2,
            .TYPE_MISMATCH: error2,
            
            .NOT_FOUND: error3,
            
            .UNRESOLVED: unresolved,
            
            .MISSING: missing
        ]
    }
    
    func styleFor(type: HighlightType) -> SPStyle? {
        return styles[type]
    }
}
