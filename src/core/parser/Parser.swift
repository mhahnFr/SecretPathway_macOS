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
    /// The start token.
    private static let startToken = Token(begin: 0, type: .EOF, end: 0)
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
        
        previous = Parser.startToken
        current  = tokenizer.nextToken()
        next     = tokenizer.nextToken()
    }
    
    /// Advances the stream by one token.
    private mutating func advance() {
        previous = current
        current  = next
        next     = tokenizer.nextToken()
    }
    
    /// Parses an `inherit` statement.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseInherit() -> ASTExpression {
        fatalError()
    }
    
    /// Parses an `#include` statement.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseInclude() -> ASTExpression {
        fatalError()
    }
    
    /// Parses a `class` definition.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseClass() -> ASTExpression {
        fatalError()
    }
    
    /// Parses a modifier list.
    ///
    /// - Returns: The parsed modifiers.
    private mutating func parseModifiers() -> [ASTExpression] {
        fatalError()
    }
    
    /// Parses a type.
    ///
    /// - Returns: The parsed type.
    private mutating func parseType() -> ASTExpression {
        fatalError()
    }
    
    /// Parses a name.
    ///
    /// - Returns: The parsed name.
    private mutating func parseName() -> ASTExpression {
        fatalError()
    }
    
    /// Parses the parameter definition list of a function definition.
    ///
    /// - Returns: The parsed parameter definitions.
    private mutating func parseParameterDefinitions() -> [ASTExpression] {
        fatalError()
    }
    
    /// Parses a block.
    ///
    /// - Returns: The parsed block.
    private mutating func parseBlock() -> ASTExpression {
        fatalError()
    }
    
    /// Parses a function definition.
    ///
    /// - Parameter modifiers: The modifier list.
    /// - Parameter type: The type.
    /// - Parameter name: The name.
    /// - Returns: The parsed function definition.
    private mutating func parseFunctionDefinition(_ modifiers: [ASTExpression],
                                                  _ type:      ASTExpression,
                                                  _ name:      ASTExpression) -> ASTExpression {
        let parameters = parseParameterDefinitions()
        let body       = parseBlock()
        
        return ASTFunctionDefinition(modifiers: modifiers, type: type, name: name, parameters: parameters, body: body)
    }
    
    /// Combines the given expressions.
    ///
    /// - Parameter main: The main expression.
    /// - Parameter parts: The parts to complete the main expression.
    /// - Returns: An `ASTCombination` of the given expressions.
    private mutating func combine(_ main: ASTExpression, _ parts: ASTExpression...) -> ASTExpression {
        var elements = [ main ]
        elements.append(contentsOf: parts)
        
        return ASTCombination(elements)
    }
    
    /// Asserts a semicolon follows after the given expression.
    ///
    /// - Parameter expression: The expression to be followed by a semicolon
    /// - Returns: The AST representation of the semicolon-ed expression.
    private mutating func assertSemicolon(for expression: ASTExpression) -> ASTExpression {
        let toReturn: ASTExpression
        
        if !current.isType(.SEMICOLON) {
            toReturn = combine(expression, ASTMissing(begin: previous.end, end: current.begin, message: "Missing ';'"))
        } else {
            toReturn = expression
        }
        
        return toReturn
    }
    
    /// Parses a normal expression.
    ///
    /// - Returns: The parsed expression.
    private mutating func parseExpression() -> ASTExpression {
        fatalError()
    }
    
    /// Parses a variable definition.
    ///
    /// - Parameter modifiers; The modifier list.
    /// - Parameter type: The type.
    /// - Parameter name: The name.
    /// - Returns: The parsed variable definition.
    private mutating func parseVariableDefinition(_ modifiers: [ASTExpression],
                                                  _ type:      ASTExpression,
                                                  _ name:      ASTExpression) -> ASTExpression {
        let toReturn: ASTExpression
        
        let variable = ASTVariableDefinition(begin:     modifiers.first?.begin ?? type.begin,
                                             end:       name.end,
                                             modifiers: modifiers,
                                             type:      type,
                                             name:      name)
        if current.isType(.SEMICOLON) {
            advance()
            toReturn = variable
        } else if current.isType(.ASSIGNMENT) {
            advance()
            toReturn = assertSemicolon(for: ASTOperation(lhs: variable, rhs: parseExpression(), operatorType: .ASSIGNMENT))
        } else {
            toReturn = combine(variable, ASTMissing(begin: previous.end, end: current.begin, message: "Missing ';'"))
        }
        
        return toReturn
    }
    
    /// Parses a variable or a function definition.
    ///
    /// - Returns: The parsed expression.
    private mutating func parseVarFunc() -> ASTExpression {
        let modifiers = parseModifiers()
        let type      = parseType()
        let name      = parseName()
        
        if current.isType(.LEFT_PAREN) {
            advance()
            return parseFunctionDefinition(modifiers, type, name)
        }
        return parseVariableDefinition(modifiers, type, name)
    }
    
    /// Parses a toplevel file statement.
    ///
    /// - Returns: The parsed expression.
    private mutating func parseToplevelExpression() -> ASTExpression {
        switch current.type {
        case .INHERIT: return parseInherit()
        case .INCLUDE: return parseInclude()
        case .CLASS:   return parseClass()
            
        default: return parseVarFunc()
        }
    }
    
    /// Parses the source code until the given end token is reached.
    ///
    /// - Parameter end: The end token type.
    /// - Returns: The read expressions.
    private mutating func parse(end: TokenType) -> [ASTExpression] {
        var expressions: [ASTExpression] = []
        
        var lastToken = Parser.startToken
        while !current.isType(.EOF) && !current.isType(end) {
            if current == lastToken {
                expressions.append(ASTWrong(token: current, message: "Unexpected token 1"))
                advance()
                continue
            } else {
                lastToken = current
            }
            expressions.append(parseToplevelExpression())
        }
        
        return expressions
    }
    
    /// Parses the source code until the end of the source code
    /// is reached.
    ///
    /// - Returns: The read expressions.
    public mutating func parse() -> [ASTExpression] {
        return parse(end: .EOF)
    }
}
