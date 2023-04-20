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

class InterpreterType: BasicType {
    static let any    = InterpreterType(type: .ANY)
    static let object = InterpreterType(type: .OBJECT)
    static let string = InterpreterType(type: .STRING_KEYWORD)
    static let symbol = InterpreterType(type: .SYMBOL_KEYWORD)
    static let int    = InterpreterType(type: .INT_KEYWORD)
    static let bool   = InterpreterType(type: .BOOL)
    static let void   = InterpreterType(type: .VOID)
    
    init(type: TokenType) {
        super.init(begin: 0, representedType: type, end: 0, typeFile: nil)
    }
}
