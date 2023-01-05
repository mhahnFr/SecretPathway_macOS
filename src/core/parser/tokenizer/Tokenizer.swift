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
        } else if stream.peek("#include") {
            return Token(begin: stream.index, type: .include, end: stream.skip(8))
        } else if stream.peek("inherit") {
            return Token(begin: stream.index, type: .inherit, end: stream.skip(7))
        } else if stream.peek("private") {
            return Token(begin: stream.index, type: .private, end: stream.skip(7))
        } else if stream.peek("protected") {
            return Token(begin: stream.index, type: .protected, end: stream.skip(9))
        } else if stream.peek("public") {
            return Token(begin: stream.index, type: .public, end: stream.skip(6))
        } else if stream.peek("override") {
            return Token(begin: stream.index, type: .override, end: stream.skip(8))
        } else if stream.peek("deprecated") {
            return Token(begin: stream.index, type: .deprecated, end: stream.skip(10))
        } else if stream.peek("new") {
            return Token(begin: stream.index, type: .new, end: stream.skip(3))
        } else if stream.peek("this") {
            return Token(begin: stream.index, type: .this, end: stream.skip(4))
        } else if stream.peek("nil") {
            return Token(begin: stream.index, type: .nil, end: stream.skip(3))
        } else if stream.peek("true") {
            return Token(begin: stream.index, type: .true, end: stream.skip(4))
        } else if stream.peek("false") {
            return Token(begin: stream.index, type: .false, end: stream.skip(5))
        } else if stream.peek("sizeof") {
            return Token(begin: stream.index, type: .sizeof, end: stream.skip(6))
        } else if stream.peek("is") {
            return Token(begin: stream.index, type: .is, end: stream.skip(2))
        } else if stream.peek("class") {
            return Token(begin: stream.index, type: .class, end: stream.skip(5))
        } else if stream.peek("void") {
            return Token(begin: stream.index, type: .void, end: stream.skip(4))
        } else if stream.peek("char") {
            return Token(begin: stream.index, type: .charKeyword, end: stream.skip(4))
        } else if stream.peek("int") {
            return Token(begin: stream.index, type: .intKeyword, end: stream.skip(3))
        } else if stream.peek("bool") {
            return Token(begin: stream.index, type: .bool, end: stream.skip(4))
        } else if stream.peek("object") {
            return Token(begin: stream.index, type: .object, end: stream.skip(6))
        } else if stream.peek("string") {
            return Token(begin: stream.index, type: .stringKeyword, end: stream.skip(6))
        } else if stream.peek("symbol") {
            return Token(begin: stream.index, type: .symbolKeyword, end: stream.skip(6))
        } else if stream.peek("mapping") {
            return Token(begin: stream.index, type: .mapping, end: stream.skip(7))
        } else if stream.peek("any") {
            return Token(begin: stream.index, type: .any, end: stream.skip(3))
        } else if stream.peek("mixed") {
            return Token(begin: stream.index, type: .mixed, end: stream.skip(5))
        } else if stream.peek("auto") {
            return Token(begin: stream.index, type: .auto, end: stream.skip(4))
        } else if stream.peek("let") {
            return Token(begin: stream.index, type: .let, end: stream.skip(3))
        } else if stream.peek("if") {
            return Token(begin: stream.index, type: .if, end: stream.skip(2))
        } else if stream.peek("else") {
            return Token(begin: stream.index, type: .else, end: stream.skip(4))
        } else if stream.peek("while") {
            return Token(begin: stream.index, type: .while, end: stream.skip(5))
        } else if stream.peek("do") {
            return Token(begin: stream.index, type: .do, end: stream.skip(2))
        } else if stream.peek("foreach") {
            return Token(begin: stream.index, type: .foreach, end: stream.skip(7))
        } else if stream.peek("for") {
            return Token(begin: stream.index, type: .for, end: stream.skip(3))
        } else if stream.peek("switch") {
            return Token(begin: stream.index, type: .switch, end: stream.skip(6))
        } else if stream.peek("case") {
            return Token(begin: stream.index, type: .case, end: stream.skip(4))
        } else if stream.peek("default") {
            return Token(begin: stream.index, type: .default, end: stream.skip(7))
        } else if stream.peek("break") {
            return Token(begin: stream.index, type: .break, end: stream.skip(5))
        } else if stream.peek("continue") {
            return Token(begin: stream.index, type: .continue, end: stream.skip(8))
        } else if stream.peek("return") {
            return Token(begin: stream.index, type: .return, end: stream.skip(6))
        } else if stream.peek("try") {
            return Token(begin: stream.index, type: .try, end: stream.skip(3))
        } else if stream.peek("catch") {
            return Token(begin: stream.index, type: .catch, end: stream.skip(5))
        } else if stream.peek("operator") {
            return Token(begin: stream.index, type: .operator, end: stream.skip(8))
        } else {
            let begin = stream.index
            var buffer = ""
            while stream.hasNext && !isSpecial(stream.peek) {
                buffer.append(stream.next())
            }
            if let number = Int(buffer) {
                return Token(begin: begin, type: .int, payload: number, end: stream.index)
            }
            return Token(begin: begin, type: .ident, end: stream.index)
        }
    }
    
    private func isSpecial(_ c: Character) -> Bool {
        return !(c.isNumber || c.isLetter || c == "_")
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
