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

/// This class represents a convenience wrapper for
/// a basic type.
class InterpreterType: BasicType {
    /// Represents the `any` type.
    static let any     = InterpreterType(type: .ANY)
    /// Represents the `object` type.
    static let object  = InterpreterType(type: .OBJECT)
    /// Represents the `string` type.
    static let string  = InterpreterType(type: .STRING_KEYWORD)
    /// Represents the `symbol` type.
    static let symbol  = InterpreterType(type: .SYMBOL_KEYWORD)
    /// Represents the `int` type.
    static let int     = InterpreterType(type: .INT_KEYWORD)
    /// Represents the `bool` type.
    static let bool    = InterpreterType(type: .BOOL)
    /// Represents the `void` type.
    static let void    = InterpreterType(type: .VOID)
    /// Represents the `char` type.
    static let char    = InterpreterType(type: .CHAR_KEYWORD)
    /// Represents the `mapping` type.
    static let mapping = InterpreterType(type: .MAPPING)
    /// Represents an unknown type.
    static let unknown = InterpreterType(type: nil)
    
    /// Wraps the given token type as a basic type.
    ///
    /// - Parameter type: The token type to represent as basic type.
    /// - Parameter name: The file name for the file annotation.
    init(type: TokenType?, file name: String? = nil) {
        var fileStrings = ASTExpression?.none
        if let name {
            fileStrings = ASTStrings(strings: [ ASTString(token: Token(begin:  0,
                                                                       type:   .STRING,
                                                                       payload: name,
                                                                       end:     0)) ])
        }
        super.init(begin: 0, representedType: type, end: 0, typeFile: fileStrings)
    }
}
