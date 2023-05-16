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
            return Token(begin: stream.index, type: .EOF, end: stream.index)
        } else if stream.peek("/*!") {
            return Token(begin: stream.index, type: .STRING, payload: readTill("!*/", skipping: 3), end: stream.index)
        } else if stream.peek("/*") {
            let begin = stream.index
            let comment = readTill("*/", skipping: 2)
            if commentTokens {
                return Token(begin: begin, type: .COMMENT_BLOCK, payload: comment, end: stream.index)
            } else {
                return nextToken()
            }
        } else if stream.peek("//") {
            let begin = stream.index
            let comment = readTill("\n", skipping: 2)
            if commentTokens {
                return Token(begin: begin, type: .COMMENT_LINE, payload: comment, end: stream.index)
            } else {
                return nextToken()
            }
        }
        else if stream.peek("(")   { return Token(begin: stream.index, type: .LEFT_PAREN,         end: stream.skip())  }
        else if stream.peek(")")   { return Token(begin: stream.index, type: .RIGHT_PAREN,        end: stream.skip())  }
        else if stream.peek("[")   { return Token(begin: stream.index, type: .LEFT_BRACKET,       end: stream.skip())  }
        else if stream.peek("]")   { return Token(begin: stream.index, type: .RIGHT_BRACKET,      end: stream.skip())  }
        else if stream.peek("{")   { return Token(begin: stream.index, type: .LEFT_CURLY,         end: stream.skip())  }
        else if stream.peek("}")   { return Token(begin: stream.index, type: .RIGHT_CURLY,        end: stream.skip())  }
        else if stream.peek("...") { return Token(begin: stream.index, type: .ELLIPSIS,           end: stream.skip(3)) }
        else if stream.peek("..")  { return Token(begin: stream.index, type: .RANGE,              end: stream.skip(2)) }
        else if stream.peek(".")   { return Token(begin: stream.index, type: .DOT,                end: stream.skip())  }
        else if stream.peek(",")   { return Token(begin: stream.index, type: .COMMA,              end: stream.skip())  }
        else if stream.peek("::")  { return Token(begin: stream.index, type: .SCOPE,              end: stream.skip(2)) }
        else if stream.peek(":")   { return Token(begin: stream.index, type: .COLON,              end: stream.skip())  }
        else if stream.peek(";")   { return Token(begin: stream.index, type: .SEMICOLON,          end: stream.skip())  }
        else if stream.peek("==")  { return Token(begin: stream.index, type: .EQUALS,             end: stream.skip(2)) }
        else if stream.peek("!=")  { return Token(begin: stream.index, type: .NOT_EQUAL,          end: stream.skip(2)) }
        else if stream.peek("<<")  { return Token(begin: stream.index, type: .LEFT_SHIFT,         end: stream.skip(2)) }
        else if stream.peek(">>")  { return Token(begin: stream.index, type: .RIGHT_SHIFT,        end: stream.skip(2)) }
        else if stream.peek("<=")  { return Token(begin: stream.index, type: .LESS_OR_EQUAL,      end: stream.skip(2)) }
        else if stream.peek("<")   { return Token(begin: stream.index, type: .LESS,               end: stream.skip())  }
        else if stream.peek(">=")  { return Token(begin: stream.index, type: .GREATER_OR_EQUAL,   end: stream.skip(2)) }
        else if stream.peek(">")   { return Token(begin: stream.index, type: .GREATER,            end: stream.skip())  }
        else if stream.peek("||")  { return Token(begin: stream.index, type: .OR,                 end: stream.skip(2)) }
        else if stream.peek("&&")  { return Token(begin: stream.index, type: .AND,                end: stream.skip(2)) }
        else if stream.peek("!")   { return Token(begin: stream.index, type: .NOT,                end: stream.skip())  }
        else if stream.peek("=")   { return Token(begin: stream.index, type: .ASSIGNMENT,         end: stream.skip())  }
        else if stream.peek("->")  { return Token(begin: stream.index, type: .ARROW,              end: stream.skip(2)) }
        else if stream.peek("&")   { return Token(begin: stream.index, type: .AMPERSAND,          end: stream.skip())  }
        else if stream.peek("|")   { return Token(begin: stream.index, type: .PIPE,               end: stream.skip())  }
        else if stream.peek("??")  { return Token(begin: stream.index, type: .DOUBLE_QUESTION,    end: stream.skip(2)) }
        else if stream.peek("?")   { return Token(begin: stream.index, type: .QUESTION,           end: stream.skip())  }
        else if stream.peek("+=")  { return Token(begin: stream.index, type: .ASSIGNMENT_PLUS,    end: stream.skip(2)) }
        else if stream.peek("-=")  { return Token(begin: stream.index, type: .ASSIGNMENT_MINUS,   end: stream.skip(2)) }
        else if stream.peek("*=")  { return Token(begin: stream.index, type: .ASSIGNMENT_STAR,    end: stream.skip(2)) }
        else if stream.peek("/=")  { return Token(begin: stream.index, type: .ASSIGNMENT_SLASH,   end: stream.skip(2)) }
        else if stream.peek("%=")  { return Token(begin: stream.index, type: .ASSIGNMENT_PERCENT, end: stream.skip(2)) }
        else if stream.peek("&=")  { return Token(begin: stream.index, type: .ASSIGNMENT_BIT_AND, end: stream.skip(2)) }
        else if stream.peek("|=")  { return Token(begin: stream.index, type: .ASSIGNMENT_BIT_OR,  end: stream.skip(2)) }
        else if stream.peek("^=")  { return Token(begin: stream.index, type: .ASSIGNMENT_BIT_XOR, end: stream.skip(2)) }
        else if stream.peek("<<=") { return Token(begin: stream.index, type: .ASSIGNMENT_L_SHIFT, end: stream.skip(3)) }
        else if stream.peek(">>=") { return Token(begin: stream.index, type: .ASSIGNMENT_R_SHIFT, end: stream.skip(3)) }
        else if stream.peek("++")  { return Token(begin: stream.index, type: .INCREMENT,          end: stream.skip(2)) }
        else if stream.peek("--")  { return Token(begin: stream.index, type: .DECREMENT,          end: stream.skip(2)) }
        else if stream.peek("+")   { return Token(begin: stream.index, type: .PLUS,               end: stream.skip())  }
        else if stream.peek("-")   { return Token(begin: stream.index, type: .MINUS,              end: stream.skip())  }
        else if stream.peek("*")   { return Token(begin: stream.index, type: .STAR,               end: stream.skip())  }
        else if stream.peek("/")   { return Token(begin: stream.index, type: .SLASH,              end: stream.skip())  }
        else if stream.peek("%")   { return Token(begin: stream.index, type: .PERCENT,            end: stream.skip())  }
        else if stream.peek("^")   { return Token(begin: stream.index, type: .BIT_XOR,            end: stream.skip())  }
        else if stream.peek("~")   { return Token(begin: stream.index, type: .BIT_NOT,            end: stream.skip())  }
        else if stream.peek("\"")  { return Token(begin: stream.index, type: .STRING,    payload: readTill("\""),             end: stream.index) }
        else if stream.peek("'")   { return Token(begin: stream.index, type: .CHARACTER, payload: readTill("'"),              end: stream.index) }
        else if stream.peek("#'")  { return Token(begin: stream.index, type: .SYMBOL,    payload: readTill("'", skipping: 2), end: stream.index) }
        else if stream.peek("#:")  { return Token(begin: stream.index, type: .SYMBOL,    payload: readSymbol(),               end: stream.index) }
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
        case "#include":   return Token(begin: begin, type: .INCLUDE,        end: end)
        case "inherit":    return Token(begin: begin, type: .INHERIT,        end: end)
        case "private":    return Token(begin: begin, type: .PRIVATE,        end: end)
        case "protected":  return Token(begin: begin, type: .PROTECTED,      end: end)
        case "public":     return Token(begin: begin, type: .PUBLIC,         end: end)
        case "static":     return Token(begin: begin, type: .STATIC,         end: end)
        case "override":   return Token(begin: begin, type: .OVERRIDE,       end: end)
        case "deprecated": return Token(begin: begin, type: .DEPRECATED,     end: end)
        case "nosave":     return Token(begin: begin, type: .NOSAVE,         end: end)
        case "new":        return Token(begin: begin, type: .NEW,            end: end)
        case "this":       return Token(begin: begin, type: .THIS,           end: end)
        case "nil":        return Token(begin: begin, type: .NIL,            end: end)
        case "true":       return Token(begin: begin, type: .TRUE,           end: end)
        case "false":      return Token(begin: begin, type: .FALSE,          end: end)
        case "sizeof":     return Token(begin: begin, type: .SIZEOF,         end: end)
        case "is":         return Token(begin: begin, type: .IS,             end: end)
        case "class":      return Token(begin: begin, type: .CLASS,          end: end)
        case "void":       return Token(begin: begin, type: .VOID,           end: end)
        case "char":       return Token(begin: begin, type: .CHAR_KEYWORD,   end: end)
        case "int":        return Token(begin: begin, type: .INT_KEYWORD,    end: end)
        case "float":      return Token(begin: begin, type: .FLOAT_KEYWORD,  end: end)
        case "bool":       return Token(begin: begin, type: .BOOL,           end: end)
        case "object":     return Token(begin: begin, type: .OBJECT,         end: end)
        case "string":     return Token(begin: begin, type: .STRING_KEYWORD, end: end)
        case "symbol":     return Token(begin: begin, type: .SYMBOL_KEYWORD, end: end)
        case "mapping":    return Token(begin: begin, type: .MAPPING,        end: end)
        case "exception":  return Token(begin: begin, type: .EXCEPTION,      end: end)
        case "any":        return Token(begin: begin, type: .ANY,            end: end)
        case "mixed":      return Token(begin: begin, type: .MIXED,          end: end)
        case "auto":       return Token(begin: begin, type: .AUTO,           end: end)
        case "let":        return Token(begin: begin, type: .LET,            end: end)
        case "if":         return Token(begin: begin, type: .IF,             end: end)
        case "else":       return Token(begin: begin, type: .ELSE,           end: end)
        case "while":      return Token(begin: begin, type: .WHILE,          end: end)
        case "do":         return Token(begin: begin, type: .DO,             end: end)
        case "foreach":    return Token(begin: begin, type: .FOREACH,        end: end)
        case "for":        return Token(begin: begin, type: .FOR,            end: end)
        case "switch":     return Token(begin: begin, type: .SWITCH,         end: end)
        case "case":       return Token(begin: begin, type: .CASE,           end: end)
        case "default":    return Token(begin: begin, type: .DEFAULT,        end: end)
        case "break":      return Token(begin: begin, type: .BREAK,          end: end)
        case "continue":   return Token(begin: begin, type: .CONTINUE,       end: end)
        case "return":     return Token(begin: begin, type: .RETURN,         end: end)
        case "try":        return Token(begin: begin, type: .TRY,            end: end)
        case "catch":      return Token(begin: begin, type: .CATCH,          end: end)
        case "operator":   return Token(begin: begin, type: .OPERATOR,       end: end)
            
        default:
            let number: Int?
            if word.starts(with: "0x") || word.starts(with: "0X") {
                number = Int(word[word.index(word.startIndex, offsetBy: 2)...], radix: 16)
            } else {
                number = Int(word)
            }
            if let number {
                return Token(begin: begin, type: .INTEGER, payload: number, end: end)
            } else if let floating = Float(word) {
                return Token(begin: begin, type: .FLOAT, payload: floating, end: end)
            }
            return Token(begin: begin, type: .IDENTIFIER, payload: word, end: end)
        }
    }
    
    private func isNumbers(_ string: String) -> Bool {
        for c in string {
            guard c.isNumber else { return false }
        }
        return true
    }
    
    /// Returns the next word read from the stream.
    ///
    /// - Returns: The next read word.
    private mutating func readWord() -> String {
        var buffer = ""
        while stream.hasNext && (!Tokenizer.isSpecial(stream.peek) || (isNumbers(buffer) && stream.peek == ".")) {
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
    static func isSpecial(_ c: Character) -> Bool {
        return !(c.isNumber || c.isLetter || c == "_" || c == "$" || c == "#")
    }
    
    /// Returns the read symbol name.
    ///
    /// - Returns: The read symbol.
    private mutating func readSymbol() -> String {
        stream.skip(2)
        
        var buffer = ""
        while stream.hasNext && !Tokenizer.isSpecial(stream.peek) {
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
        var previous: Character     = "\0"
        var overPrevious: Character = "\0"
        while stream.hasNext && !(stream.peek(end) && (previous != "\\" || overPrevious == "\\")) {
            overPrevious = previous
            previous     = stream.next()
            
            buffer.append(previous)
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
