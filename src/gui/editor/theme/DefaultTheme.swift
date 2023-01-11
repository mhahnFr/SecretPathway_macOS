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
    private let styles: [TokenType: SPStyle]
    
    /// Initializes this theme.
    init() {
        let keyword = SPStyle(bold: true, foreground: NSColor(red: 0.015, green: 0.388, blue: 0.51, alpha: 1))
        let type    = SPStyle(foreground: NSColor(red: 0.015, green: 0.51, blue: 0.51, alpha: 1))
        let control = SPStyle(foreground: NSColor(red: 0.714, green: 0.004, blue: 0.09, alpha: 1))
        let id      = SPStyle(foreground: NSColor(red: 0.702, green: 0.043, blue: 0.749, alpha: 1))
        let flow    = SPStyle(foreground: NSColor(red: 0.086, green: 0.459, blue: 0.02, alpha: 1))
        let comment = SPStyle(italic: true, foreground: .gray)
        let op      = SPStyle()
        let const   = SPStyle(foreground: NSColor(red: 0.671, green: 0.627, blue: 0.012, alpha: 1))
        styles = [
            .identifier: id,
            
            .nil:   keyword,
            .true:  keyword,
            .false: keyword,
            
            .include:    control,
            .inherit:    control,
            .private:    control,
            .protected:  control,
            .public:     control,
            .override:   control,
            .deprecated: control,
            .new:        control,
            .this:       control,
            .sizeof:     control,
            .is:         control,
            .class:      control,
            
            .if:         flow,
            .else:       flow,
            .while:      flow,
            .do:         flow,
            .for:        flow,
            .foreach:    flow,
            .switch:     flow,
            .case:       flow,
            .default:    flow,
            .break:      flow,
            .continue:   flow,
            .return:     flow,
            .try:        flow,
            .catch:      flow,
            
            .void:          type,
            .charKeyword:   type,
            .intKeyword:    type,
            .bool:          type,
            .object:        type,
            .stringKeyword: type,
            .symbolKeyword: type,
            .mapping:       type,
            .any:           type,
            .mixed:         type,
            .auto:          type,
            .operator:      type,
            .let:           type,
            
            .int:       const,
            .string:    const,
            .character: const,
            .symbol:    const,
            
            .commentLine:  comment,
            .commentBlock: comment,
            
            .equals:            op,
            .notEquals:         op,
            .less:              op,
            .lessOrEqual:       op,
            .greater:           op,
            .greaterOrEqual:    op,
            .or:                op,
            .and:               op,
            .not:               op,
            .assignment:        op,
            .arrow:             op,
            .pArrow:            op,
            .ampersand:         op,
            .pipe:              op,
            .leftShift:         op,
            .rightShift:        op,
            .doubleQuestion:    op,
            .question:          op,
            .increment:         op,
            .decrement:         op,
            .plus:              op,
            .minus:             op,
            .star:              op,
            .slash:             op,
            .percent:           op,
            .assignmentPlus:    op,
            .assignmentStar:    op,
            .assignmentMinus:   op,
            .assignmentSlash:   op,
            .assignmentPercent: op
        ]
    }
    
    func styleFor(tokenType: TokenType) -> SPStyle {
        return styles[tokenType] ?? SPStyle()
    }
}
