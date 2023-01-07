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
    /// Indicates whether to generate comment tokens.
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
        return nextWord()
    }
    
    /// Constructs and returns a token from the next word read from the stream.
    ///
    /// - Returns: A token constructed from the next read word.
    private mutating func nextWord() -> Token {
        let begin = stream.index
        let word  = readWord()
        let end   = stream.index
        
        switch word {
        case "#include":   return Token(begin: begin, type: .include,       end: end)
        case "inherit":    return Token(begin: begin, type: .inherit,       end: end)
        case "private":    return Token(begin: begin, type: .private,       end: end)
        case "protected":  return Token(begin: begin, type: .protected,     end: end)
        case "public":     return Token(begin: begin, type: .public,        end: end)
        case "override":   return Token(begin: begin, type: .override,      end: end)
        case "deprecated": return Token(begin: begin, type: .deprecated,    end: end)
        case "new":        return Token(begin: begin, type: .new,           end: end)
        case "this":       return Token(begin: begin, type: .this,          end: end)
        case "nil":        return Token(begin: begin, type: .nil,           end: end)
        case "true":       return Token(begin: begin, type: .true,          end: end)
        case "false":      return Token(begin: begin, type: .false,         end: end)
        case "sizeof":     return Token(begin: begin, type: .sizeof,        end: end)
        case "is":         return Token(begin: begin, type: .is,            end: end)
        case "class":      return Token(begin: begin, type: .class,         end: end)
        case "void":       return Token(begin: begin, type: .void,          end: end)
        case "char":       return Token(begin: begin, type: .charKeyword,   end: end)
        case "int":        return Token(begin: begin, type: .intKeyword,    end: end)
        case "bool":       return Token(begin: begin, type: .bool,          end: end)
        case "object":     return Token(begin: begin, type: .object,        end: end)
        case "string":     return Token(begin: begin, type: .stringKeyword, end: end)
        case "symbol":     return Token(begin: begin, type: .symbolKeyword, end: end)
        case "mapping":    return Token(begin: begin, type: .mapping,       end: end)
        case "any":        return Token(begin: begin, type: .any,           end: end)
        case "mixed":      return Token(begin: begin, type: .mixed,         end: end)
        case "auto":       return Token(begin: begin, type: .auto,          end: end)
        case "let":        return Token(begin: begin, type: .let,           end: end)
        case "if":         return Token(begin: begin, type: .if,            end: end)
        case "else":       return Token(begin: begin, type: .else,          end: end)
        case "while":      return Token(begin: begin, type: .while,         end: end)
        case "do":         return Token(begin: begin, type: .do,            end: end)
        case "foreach":    return Token(begin: begin, type: .foreach,       end: end)
        case "for":        return Token(begin: begin, type: .for,           end: end)
        case "switch":     return Token(begin: begin, type: .switch,        end: end)
        case "case":       return Token(begin: begin, type: .case,          end: end)
        case "default":    return Token(begin: begin, type: .default,       end: end)
        case "break":      return Token(begin: begin, type: .break,         end: end)
        case "continue":   return Token(begin: begin, type: .continue,      end: end)
        case "return":     return Token(begin: begin, type: .return,        end: end)
        case "try":        return Token(begin: begin, type: .try,           end: end)
        case "catch":      return Token(begin: begin, type: .catch,         end: end)
        case "operator":   return Token(begin: begin, type: .operator,      end: end)
            
        default:
            if let number = Int(word) {
                return Token(begin: begin, type: .int, payload: number, end: end)
            }
            return Token(begin: begin, type: .identifier, payload: word, end: end)
        }
    }
    
    /// Returns the next word read from the stream.
    ///
    /// - Returns: The next read word.
    private mutating func readWord() -> String {
        var buffer = ""
        while stream.hasNext && !isSpecial(stream.peek) {
            buffer.append(stream.next())
        }
        if buffer.isEmpty && stream.hasNext {
            // Unrecognized character, use as word to prevent endless loop
            buffer.append(stream.next())
        }
        return buffer
    }
    
    /// Returns whether the given character si to be treated as a special character.
    ///
    /// - Parameter c: The character to be checked.
    /// - Returns: Whether the given character is a special one.
    private func isSpecial(_ c: Character) -> Bool {
        return !(c.isNumber || c.isLetter || c == "_")
    }
    
    /// Returns the read symbol name.
    ///
    /// - Returns: The read symbol.
    private mutating func readSymbol() -> String {
        stream.skip(2)
        
        var buffer = ""
        while stream.hasNext && (stream.peek.isLetter || stream.peek.isNumber || stream.peek == "_" || stream.peek == "$" || stream.peek == "#") {
            buffer.append(stream.next())
        }
        return buffer
    }
    
    /// Returns a string read from the stream.
    ///
    /// The first given amount of characters are skipped, the string is read until
    /// the end is read. The given end string is not part of the string, but consumed
    /// from the stream.
    ///
    /// - Parameter end: The end pattern.
    /// - Parameter skipping: The amount of characters to be skipped before reading.
    /// - Returns: The read string.
    private mutating func readTill(_ end: String, skipping: Int = 1) -> String {
        stream.skip(skipping)
        
        var buffer = ""
        while stream.hasNext && !stream.peek(end) {
            buffer.append(stream.next())
        }
        stream.skip(end.count)
        return buffer
    }
    
    /// Consumes the whitespaces from the stream.
    private mutating func skipWhitespaces() {
        while stream.hasNext && stream.peek.isWhitespace {
            stream.next()
        }
    }
}
