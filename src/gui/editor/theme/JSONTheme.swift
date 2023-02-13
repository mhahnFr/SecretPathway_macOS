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

/// Represents a `Codable` theme.
struct JSONTheme: SPTheme, Codable {
    /// The styles used for the token types.
    let styles: [JSONStyle]
    /// A dictionary consisting of the token type and the name of
    /// the style to be used.
    let tokenStyles: [String: String]
    
    private var cached: [TokenType: SPStyle] = [:]
    
    private enum CodingKeys: CodingKey {
        case styles, tokenStyles
    }
    
    mutating func styleFor(tokenType: TokenType) -> SPStyle {
        if cached.isEmpty { validate() }
        
        return cached[tokenType] ?? SPStyle()
    }
    
    private func findStyleBy(name: String) -> JSONStyle? {
        for style in styles {
            if style.name == name {
                return style
            }
        }
        
        return nil
    }
    
    mutating func validate() {
        for (typeName, styleName) in tokenStyles {
            if let type = TokenType(rawValue: typeName), let style = findStyleBy(name: styleName) {
                cached[type] = style.native
            }
        }
    }
}
