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

/// Represents a tokenizer for LPC source code.
struct Tokenizer {
    /// The stream to read characters from.
    var stream: StringStream
    var commentTokens = false
    
    /// Returns the next recognized token.
    ///
    /// - Returns: The next recognized token.
    mutating func nextToken() -> Token {
        skipWhitespaces()
        
        if !stream.hasNext {
            return Token(begin: stream.index, type: .eof, end: stream.index)
        } else if stream.peek("/*!") {
            return Token(begin: stream.index, type: .string, payload: readTill("!*/", skipping: 3), end: stream.index)
        } else if stream.peek("/*") {
            let begin = stream.index
            let comment = readTill("*/", skipping: 2)
            if commentTokens {
                return Token(begin: begin, type: .commentBlock, payload: comment, end: stream.index)
            } else {
                return nextToken()
            }
        } else if stream.peek("//") {
            let begin = stream.index
            let comment = readTill("\n", skipping: 2)
            if commentTokens {
                return Token(begin: begin, type: .commentLine, payload: comment, end: stream.index)
            } else {
                return nextToken()
            }
        } else if stream.peek("(") {
            return Token(begin: stream.index, type: .leftParen, end: stream.skip())
        } else if stream.peek(")") {
            return Token(begin: stream.index, type: .rightParen, end: stream.skip())
        } else if stream.peek("[") {
            return Token(begin: stream.index, type: .leftBrack, end: stream.skip())
        } else if stream.peek("]") {
            return Token(begin: stream.index, type: .rightBrack, end: stream.skip())
        } else if stream.peek("{") {
            return Token(begin: stream.index, type: .leftCurly, end: stream.skip())
        } else if stream.peek("}") {
            return Token(begin: stream.index, type: .rightCurly, end: stream.skip())
        } else if stream.peek("...") {
            return Token(begin: stream.index, type: .ellipsis, end: stream.skip(3))
        } else if stream.peek(".") {
            return Token(begin: stream.index, type: .dot, end: stream.skip())
        } else if stream.peek(",") {
            return Token(begin: stream.index, type: .comma, end: stream.skip())
        } else if stream.peek("::") {
            return Token(begin: stream.index, type: .scope, end: stream.skip(2))
        } else if stream.peek(":") {
            return Token(begin: stream.index, type: .colon, end: stream.skip())
        } else if stream.peek(";") {
            return Token(begin: stream.index, type: .semicolon, end: stream.skip())
        } else if stream.peek("==") {
            return Token(begin: stream.index, type: .equals, end: stream.skip(2))
        } else if stream.peek("!=") {
            return Token(begin: stream.index, type: .notEquals, end: stream.skip(2))
        } else if stream.peek("<<") {
            return Token(begin: stream.index, type: .leftShift, end: stream.skip(2))
        } else if stream.peek(">>") {
            return Token(begin: stream.index, type: .rightShift, end: stream.skip(2))
        } else if stream.peek("<=") {
            return Token(begin: stream.index, type: .lessOrEqual, end: stream.skip(2))
        } else if stream.peek("<") {
            return Token(begin: stream.index, type: .less, end: stream.skip())
        } else if stream.peek(">=") {
            return Token(begin: stream.index, type: .greaterOrEqual, end: stream.skip(2))
        } else if stream.peek(">") {
            return Token(begin: stream.index, type: .greater, end: stream.skip())
        } else if stream.peek("||") {
            return Token(begin: stream.index, type: .not, end: stream.skip(2))
        } else if stream.peek("&&") {
            return Token(begin: stream.index, type: .and, end: stream.skip(2))
        } else if stream.peek("!") {
            return Token(begin: stream.index, type: .not, end: stream.skip())
        } else if stream.peek("=") {
            return Token(begin: stream.index, type: .assignment, end: stream.skip())
        } else if stream.peek("->") {
            return Token(begin: stream.index, type: .arrow, end: stream.skip(2))
        } else if stream.peek("|->") {
            return Token(begin: stream.index, type: .pArrow, end: stream.skip(3))
        } else if stream.peek("&") {
            return Token(begin: stream.index, type: .ampersand, end: stream.skip())
        } else if stream.peek("|") {
            return Token(begin: stream.index, type: .pipe, end: stream.skip())
        } else if stream.peek("??") {
            return Token(begin: stream.index, type: .doubleQuestion, end: stream.skip(2))
        } else if stream.peek("?") {
            return Token(begin: stream.index, type: .question, end: stream.skip())
        } else if stream.peek("+=") {
            return Token(begin: stream.index, type: .assignmentPlus, end: stream.skip(2))
        } else if stream.peek("-=") {
            return Token(begin: stream.index, type: .assignmentMinus, end: stream.skip(2))
        } else if stream.peek("*=") {
            return Token(begin: stream.index, type: .assignmentStar, end: stream.skip(2))
        } else if stream.peek("/=") {
            return Token(begin: stream.index, type: .assignmentSlash, end: stream.skip(2))
        } else if stream.peek("%=") {
            return Token(begin: stream.index, type: .assignmentPercent, end: stream.skip(2))
        } else if stream.peek("++") {
            return Token(begin: stream.index, type: .increment, end: stream.skip(2))
        } else if stream.peek("--") {
            return Token(begin: stream.index, type: .decrement, end: stream.skip(2))
        } else if stream.peek("+") {
            return Token(begin: stream.index, type: .plus, end: stream.skip())
        } else if stream.peek("-") {
            return Token(begin: stream.index, type: .minus, end: stream.skip())
        } else if stream.peek("*") {
            return Token(begin: stream.index, type: .star, end: stream.skip())
        } else if stream.peek("/") {
            return Token(begin: stream.index, type: .slash, end: stream.skip())
        } else if stream.peek("%") {
            return Token(begin: stream.index, type: .percent, end: stream.skip())
        } else if stream.peek("\"") {
            return Token(begin: stream.index, type: .string, payload: readTill("\""), end: stream.index)
        } else if stream.peek("'") {
            return Token(begin: stream.index, type: .character, payload: readTill("'"), end: stream.index)
        } else if stream.peek("#'") {
            return Token(begin: stream.index, type: .symbol, payload: readTill("'", skipping: 2), end: stream.index)
        } else if stream.peek("#:") {
            return Token(begin: stream.index, type: .symbol, payload: readSymbol(), end: stream.index)
        }
        // TODO: Keywords
        
        return Token(begin: 0, type: .eof, payload: nil, end: 0)
    }
    
    private mutating func readSymbol() -> String {
        stream.skip(2)
        
        var buffer = ""
        while stream.hasNext && (stream.peek.isLetter || stream.peek.isNumber || stream.peek == "_" || stream.peek == "$" || stream.peek == "#") {
            buffer.append(stream.next())
        }
        return buffer
    }
    
    private mutating func readTill(_ end: String, skipping: Int = 1) -> String {
        stream.skip(skipping)
        
        var buffer = ""
        while stream.hasNext && !stream.peek(end) {
            buffer.append(stream.next())
        }
        stream.skip(end.count)
        return buffer
    }
    
    private mutating func skipWhitespaces() {
        while stream.hasNext && stream.peek.isWhitespace {
            stream.next()
        }
    }
}
