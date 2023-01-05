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
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
 */

/// This enumeration consists of the possible token types.
enum TokenType {
    case eof,
    
    ident, int, string, character, symbol,
    
    leftParen, rightParen, leftBrack, rightBrack, leftCurly, rightCurly,
    dot, comma, scope, colon, semicolon, ellipsis,
    
    equals, notEquals, less, lessOrEqual, greater, greaterOrEqual,
    
    or, and, not,
    
    assignment, arrow, pArrow, ampersand, pipe, leftShift, rightShift,
    doubleQuestion, question,
    
    increment, decrement,
    
    plus, minus, star, slash, percent,
    
    assignmentPlus, assignmentMinus, assignmentStar, assignmentSlash, assignmentPercent,
    
    include, inherit, `private`, protected, `public`, `override`, deprecated, new,
    this, `nil`, `true`, `false`, sizeof, `is`, `class`, void, charKeyword, intKeyword,
    bool, object, stringKeyword, symbolKeyword, mapping, any, mixed, auto, `operator`,
    `let`, `if`, `else`, `while`, `do`, `for`, foreach, `switch`, `case`, `default`,
    `break`, `continue`, `return`, `try`, `catch`,
    
    commentBlock, commentLine
}
