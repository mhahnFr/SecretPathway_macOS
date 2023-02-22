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

/// This struct parses LPC source code.
struct Parser {
    /// The tokenizer splitting the source code.
    private var tokenizer: Tokenizer
    /// The token that was previously in the stream..
    private var previous: Token
    /// The token currently in the stream.
    private var current: Token
    /// The next token in the stream.
    private var next: Token
    
    /// Initializes this parser using the given source code.
    ///
    /// - Parameter text: The source code to be parsed.
    init(text: any StringProtocol) {
        tokenizer = Tokenizer(stream: StringStream(text: text))
        
        previous = Token(begin: 0, type: .EOF, end: 0)
        current  = tokenizer.nextToken()
        next     = tokenizer.nextToken()
    }
    
    /// Advances the stream by one token.
    private mutating func advance() {
        previous = current
        current  = next
        next     = tokenizer.nextToken()
    }
    
    /// Parses the source code until the given end token is reached.
    ///
    /// - Parameter end: The end token type.
    /// - Returns: The read expressions.
    private mutating func parse(end: TokenType) -> [ASTExpression] {
        // TODO: Implement
        return []
    }
    
    /// Parses the source code until the end of the source code
    /// is reached.
    ///
    /// - Returns: The read expressions.
    public mutating func parse() -> [ASTExpression] {
        return parse(end: .EOF)
    }
}
