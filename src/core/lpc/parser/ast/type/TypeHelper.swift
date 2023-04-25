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

struct TypeHelper {
    private init() {}
    
    static func tokenTypeString(_ type: TokenType) -> String {
        switch type {
        case .INT_KEYWORD:    return "int"
        case .CHAR_KEYWORD:   return "char"
        case .STRING_KEYWORD: return "string"
        case .SYMBOL_KEYWORD: return "symbol"
        default:              return type.rawValue.lowercased()
        }
    }
    
    static func unwrap(_ expression: ASTExpression) -> AbstractType? {
        if let direct = expression as? AbstractType {
            return direct
        } else if let combination = expression as? ASTCombination {
            for element in combination.expressions {
                if let found = element as? AbstractType {
                    return found
                }
            }
        }
        return nil
    }
}