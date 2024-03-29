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
    /// The token that was previously in the stream.
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
    
    /// Advances the stream by the given count of tokens.
    ///
    /// - Parameter count: The count of tokens to advance.
    private mutating func advance(count: Int) {
        for _ in 0 ..< count {
            advance()
        }
    }
    
    /// Parses a string expression. Multiple following strings
    /// are concatenated.
    ///
    /// - Returns: The AST representation of the read strings.
    private mutating func parseStrings() -> ASTExpression {
        var toReturn: [ASTExpression] = []
        
        while current.isType(.STRING) {
            toReturn.append(ASTString(token: current))
            advance()
        }
        
        return ASTStrings(strings: toReturn)
    }
    
    /// Parses an `inherit` statement.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseInherit() -> ASTExpression {
        let toReturn: ASTExpression
        
        advance()
        if current.isType(.SEMICOLON) {
            toReturn = ASTInheritance(begin: previous.begin, end: current.end, inherited: nil)
            advance()
        } else if next.isType(.SEMICOLON) && !current.isType(.STRING) {
            toReturn = combine(ASTInheritance(begin: previous.begin, end: next.end, inherited: nil),
                               ASTWrong(token: current, message: "Expected a string literal", expected: .STRINGS))
        } else if current.isType(.STRING) {
            let begin   = previous.begin
            let strings = parseStrings()
            
            toReturn = assertSemicolon(for: ASTInheritance(begin: begin, end: (current.isType(.SEMICOLON) ? current : previous).end, inherited: strings))
        } else if !current.isType(.SEMICOLON) && !next.isType(.SEMICOLON) {
            toReturn = combine(ASTInheritance(begin: previous.begin, end: previous.end, inherited: nil),
                               ASTMissing(begin:    previous.end,
                                          end:      current.begin,
                                          message:  "Expected ';'",
                                          expected: .SEMICOLON))
        } else {
            toReturn = ASTInheritance(begin: previous.begin, end: next.end, inherited: nil)
            advance()
        }
        return toReturn
    }
    
    /// Parses an `#include` statement.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseInclude() -> ASTExpression {
        advance()
        
        if !current.isType(.STRING) {
            return ASTInclude(begin: previous.begin, end: current.begin, included:
                                ASTMissing(begin:    previous.end,
                                           end:      current.begin,
                                           message:  "Expected a string literal",
                                           expected: .STRINGS))
        }
        let begin   = previous.begin
        let strings = parseStrings()
        return ASTInclude(begin: begin, end: previous.end, included: strings)
    }
    
    /// Parses a `class` definition.
    ///
    /// - Returns: The parsed statement.
    private mutating func parseClass() -> ASTExpression {
        var parts: [ASTExpression] = []
        let begin = current.begin
        
        advance()
        
        let name = parseName()
        
        if current.isType(.SEMICOLON, .STRING) || (!current.isType(.LEFT_CURLY) && next.isType(.SEMICOLON)) {
            let inheritance: ASTExpression?
            
            if current.isType(.STRING) {
                let inheritanceBegin  = current.begin
                let inheritExpression = parseStrings()
                inheritance = ASTInheritance(begin: inheritanceBegin, end: previous.end, inherited: inheritExpression)
            } else if current.isType(.SEMICOLON) {
                inheritance = nil
            } else {
                inheritance = combine(ASTInheritance(begin: current.begin, end: current.end, inherited: nil),
                                      ASTWrong(token: current, message: "Expected a string literal", expected: .STRINGS))
            }
            return assertSemicolon(for: ASTClass(begin: begin, name: name, inheritance: inheritance))
        } else if !current.isType(.LEFT_CURLY) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '{'",
                                    expected: .LEFT_CURLY))
        } else {
            advance()
        }
        
        let statements = parse(end: .RIGHT_CURLY)
        if !current.isType(.RIGHT_CURLY) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '}'",
                                    expected: .RIGHT_CURLY))
        } else {
            advance()
        }
        if !current.isType(.SEMICOLON) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ';'", expected: .SEMICOLON))
        } else {
            advance()
        }
        let c = ASTClass(begin: begin, name: name, statements: statements)
        if !parts.isEmpty {
            return combine(c, parts)
        }
        return c
    }
    
    /// Returns whether the given token represents a modifier.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token represents a modifier.
    private func isModifier(_ token: Token) -> Bool {
        token.isType(.PRIVATE, .PROTECTED, .PUBLIC, .DEPRECATED, .OVERRIDE, .NOSAVE, .STATIC)
    }
    
    /// Parses a modifier list.
    ///
    /// - Returns: The parsed modifiers.
    private mutating func parseModifiers() -> [ASTExpression] {
        var toReturn: [ASTExpression] = []
        
        while !current.isType(.EOF) {
            if isModifier(current) {
                toReturn.append(ASTModifier(token: current))
            } else if isModifier(next) /* || isType(next) */ {
                toReturn.append(combine(ASTModifier(begin: current.begin, end: current.end),
                                        ASTWrong(token: current, message: "Expected a modifier", expected: .MODIFIER)))
            } else {
                break
            }
            advance()
        }
        
        return toReturn
    }
    
    /// Parses a function reference type.
    ///
    /// - Parameter returnType: The already parsed return type.
    /// - Returns: The parsed function reference type.
    private mutating func parseFunctionReferenceType(returnType: ASTExpression) -> ASTExpression {
        var paramTypes: [ASTExpression] = []
        var parts: [ASTExpression] = []
        var variadic = false
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '('",
                                    expected: .LEFT_PAREN))
        } else {
            advance()
        }
        
        if !current.isType(.RIGHT_PAREN) {
            repeat {
                if current.isType(.DOT, .RANGE, .ELLIPSIS) {
                    if !current.isType(.ELLIPSIS) {
                        parts.append(ASTWrong(token: current, message: "Expected '...'", expected: .ELLIPSIS))
                    }
                    advance()
                    if !current.isType(.RIGHT_PAREN) {
                        parts.append(ASTMissing(begin:    previous.end,
                                                end:      current.begin,
                                                message:  "Missing ')'",
                                                expected: .RIGHT_PAREN))
                    } else {
                        advance()
                    }
                    variadic = true
                    break
                } else if current.isType(.RIGHT_PAREN) {
                    parts.append(ASTMissing(begin:    previous.end,
                                            end:      current.begin,
                                            message:  "Missing type",
                                            expected: .TYPE))
                } else {
                    paramTypes.append(parseType())
                }
                
                if current.isType(.RIGHT_PAREN) {
                    advance()
                    break
                } else if !current.isType(.COMMA) {
                    parts.append(ASTMissing(begin:    previous.end,
                                            end:      current.begin,
                                            message:  "Missing ','",
                                            expected: .COMMA))
                } else {
                    advance()
                }
            } while !current.isType(.EOF)
        } else {
            advance()
        }
        
        let toReturn = FunctionReferenceType(returnType: returnType, parameterTypes: paramTypes, variadic: variadic, end: previous.end)
        return recurr(type: parts.isEmpty ? toReturn : combine(toReturn, parts))
    }
    
    /// Parses an array type.
    ///
    /// - Parameter underlying: The already parsed underlying type.
    /// - Returns: The parsed array type.
    private mutating func parseArrayType(underlying: ASTExpression) -> ASTExpression {
        let part: ASTExpression?
        if current.isType(.LEFT_BRACKET) && !next.isType(.RIGHT_BRACKET) {
            advance()
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ']'", expected: .RIGHT_BRACKET)
        } else if current.isType(.RIGHT_BRACKET) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing '['", expected: .LEFT_BRACKET)
            advance()
        } else if current.isType(.LEFT_BRACKET) && next.isType(.RIGHT_BRACKET) {
            advance(count: 2)
            part = nil
        } else {
            advance()
            part = nil
        }
        let toReturn = ArrayType(underlyingType: underlying, end: previous.end)
        if let part {
            return recurr(type: combine(toReturn, part))
        }
        return recurr(type: toReturn)
    }
    
    /// Enters recursive type parsing if necessary.
    ///
    /// - Parameter type: The already parsed type.
    /// - Returns: The recursively parsed type or the given type.
    private mutating func recurr(type: ASTExpression) -> ASTExpression {
        switch current.type {
        case .LEFT_PAREN:    return parseFunctionReferenceType(returnType: type)
            
        case .STAR,
             .LEFT_BRACKET,
             .RIGHT_BRACKET: return parseArrayType(underlying: type)
            
        case .PIPE:          return parseOrType(lhs: type)
            
        default:             return type
        }
    }
    
    /// Parses an `|` type.
    ///
    /// - Parameter lhs: The already parsed left-hand-side type.
    /// - Returns: The parsed type.
    private mutating func parseOrType(lhs: ASTExpression) -> ASTExpression {
        advance()
        return recurr(type: OrType(lhs: lhs, rhs: parseType()))
    }
    
    /// Parses a parenthesized type declaration.
    ///
    /// - Returns: The parsed type expression.
    private mutating func parseParenthesizedType() -> ASTExpression {
        var parts = [ASTExpression]()
        advance()
        
        let type: ASTExpression
        if current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing type", expected: .TYPE))
            type = ASTEmpty(previous.end, current.begin)
        } else {
            type = parseType()
        }
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing ')'",
                                    expected: .RIGHT_PAREN))
        } else {
            advance()
        }
        
        let toReturn: ASTExpression
        if !parts.isEmpty {
            toReturn = combine(type, parts)
        } else {
            toReturn = type
        }
        
        return recurr(type: toReturn)
    }
    
    /// Parses a type.
    ///
    /// - Returns: The parsed type.
    private mutating func parseType() -> ASTExpression {
        guard !current.isType(.LEFT_PAREN) else { return parseParenthesizedType() }
        
        var parts: [ASTExpression] = []
        let begin = current.begin
        
        let type: TokenType?
        if !isType(current) && !current.isType(.LESS, .GREATER, .STRING) {
            parts.append(ASTWrong(token: current, message: "Expected a type", expected: .TYPE))
            type = nil
            advance()
        } else if !isType(current) && current.isType(.LESS, .GREATER, .STRING) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing type", expected: .TYPE))
            type = nil
        } else {
            type = current.type
            advance()
        }
        
        let toReturn: ASTExpression
        if current.isType(.LESS, .GREATER, .STRING) {
            // Has type file
            let typeToken = previous
            if !current.isType(.LESS) {
                parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '<'", expected: .LESS))
            } else {
                advance()
            }
            let stringPart: ASTExpression?
            if !current.isType(.STRING) {
                if !current.isType(.GREATER) {
                    if type == .EXCEPTION {
                        stringPart = ASTName(token: current)
                    } else {
                        stringPart = nil
                        parts.append(ASTWrong(token: current, message: "Expected string literal", expected: .STRINGS))
                    }
                    advance()
                } else {
                    stringPart = nil
                    parts.append(ASTMissing(begin:    previous.end,
                                            end:      current.begin,
                                            message:  "Missing annotation",
                                            expected: .NAME))
                }
            } else {
                stringPart = parseStrings()
            }
            
            if isType(typeToken) {
                if stringPart?.type == .STRINGS && type != .OBJECT {
                    parts.append(ASTWrong(token:    typeToken,
                                          message:  "File annotation is only allowed for 'object'",
                                          expected: .OBJECT))
                } else if type != .EXCEPTION && type != .OBJECT {
                    parts.append(ASTWrong(token:    typeToken,
                                          message:  "Type annotation is only allowed for 'object' and 'exception'",
                                          expected: nil))
                }
            }
            
            if !current.isType(.GREATER) {
                parts.append(ASTMissing(begin:    previous.end,
                                        end:      current.begin,
                                        message:  "Missing '>'",
                                        expected: .GREATER))
            } else {
                advance()
            }
            toReturn = BasicType(begin: begin, representedType: type, end: previous.end, typeFile: stringPart)
        } else {
            // Just a single type
            toReturn = BasicType(begin: begin, representedType: type, end: previous.end, typeFile: nil)
        }
        
        return recurr(type: parts.isEmpty ? toReturn : combine(toReturn, parts))
    }
    
    /// Parses a name.
    ///
    /// - Returns: The parsed name.
    private mutating func parseName() -> ASTExpression {
        let toReturn: ASTExpression
        
        if current.isType(.OPERATOR) {
            let begin = current.begin
            advance()
            
            let part: ASTExpression?
            if !isOperator(current) {
                part = ASTMissing(begin:    previous.end,
                                  end:      current.begin,
                                  message:  "Missing operator",
                                  expected: .OPERATION)
            } else {
                part = nil
                advance()
            }
            let identifier = ASTOperatorName(begin: begin, token: previous)
            if let part {
                toReturn = combine(identifier, part)
            } else {
                toReturn = identifier
            }
        } else if isType(current) || isModifier(current) {
            toReturn = combine(ASTName(begin: current.begin, end: current.end),
                               ASTWrong(token: current, message: "Expected a name", expected: .NAME))
            advance()
        } else if !current.isType(.IDENTIFIER) {
            toReturn = combine(ASTName(begin: previous.end, end: current.begin),
                               ASTMissing(begin:    previous.end,
                                          end:      current.begin,
                                          message:  "Missing name",
                                          expected: .NAME))
        } else {
            toReturn = ASTName(token: current)
            advance()
        }
        
        return toReturn
    }
    
    /// Parses the parameter definition list of a function definition.
    ///
    /// - Returns: The parsed parameter definitions.
    private mutating func parseParameterDefinitions() -> [ASTExpression] {
        var toReturn: [ASTExpression] = []
        
        if !current.isType(.RIGHT_PAREN) {
            var stop = false
            repeat {
                if current.isType(.ELLIPSIS) && next.isType(.RIGHT_PAREN, .LEFT_CURLY) {
                    toReturn.append(ASTEllipsis(current))
                    if next.isType(.LEFT_CURLY) {
                        toReturn.append(ASTMissing(begin:    current.end,
                                                   end:      next.begin,
                                                   message:  "Expected ')'",
                                                   expected: .RIGHT_PAREN))
                        advance()
                    } else {
                        advance(count: 2)
                    }
                    break
                } else if current.isType(.RIGHT_PAREN) {
                    toReturn.append(ASTMissing(begin:    previous.end,
                                               end:      current.begin,
                                               message:  "Missing parameter",
                                               expected: .PARAMETER))
                    advance()
                    break
                }
                
                let type = parseType()
                
                let name: ASTExpression
                if !current.isType(.IDENTIFIER) {
                    if current.isType(.COMMA, .RIGHT_PAREN) {
                        name = combine(ASTName(begin: previous.end, end: current.begin),
                                       ASTMissing(begin:    previous.end,
                                                  end:      current.begin,
                                                  message:  "Parameter's name missing",
                                                  expected: .NAME))
                    } else {
                        name = combine(ASTName(begin: current.begin, end: current.end),
                                       ASTWrong(token: current, message: "Expected parameter's name", expected: .NAME))
                        advance()
                    }
                } else {
                    name = ASTName(token: current)
                    advance()
                }
                
                toReturn.append(ASTParameter(type: type, name: name))
                
                if current.isType(.RIGHT_PAREN, .LEFT_CURLY) {
                    stop = true
                    if current.isType(.LEFT_CURLY) {
                        toReturn.append(ASTMissing(begin:    previous.end,
                                                   end:      current.begin,
                                                   message:  "Expected ')'",
                                                   expected: .RIGHT_PAREN))
                    } else {
                        advance()
                    }
                } else if !current.isType(.COMMA) {
                    toReturn.append(ASTMissing(begin:    previous.end,
                                               end:      current.begin,
                                               message:  "Expected ','",
                                               expected: .COMMA))
                } else {
                    advance()
                }
            } while !stop && !current.isType(.EOF)
        } else {
            advance()
        }
        
        return toReturn
    }
    
    /// Returns whether the given type represents an operator.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token represents an operator.
    private func isOperator(_ token: Token) -> Bool {
        token.isType(.DOT, .ARROW, .PIPE, .LEFT_SHIFT, .RIGHT_SHIFT, .DOUBLE_QUESTION, .QUESTION,
                     .PLUS, .MINUS, .STAR, .SLASH, .PERCENT, .LESS, .LESS_OR_EQUAL, .GREATER, .IS,
                     .GREATER_OR_EQUAL, .EQUALS, .NOT_EQUAL, .AMPERSAND, .AND, .OR, .LEFT_BRACKET,
                     .BIT_XOR, .BIT_NOT, .SCOPE)
    }
    
    /// Returns whether the given token represents a type.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token represents a type.
    private func isType(_ token: Token) -> Bool {
        token.isType(.VOID, .CHAR_KEYWORD, .INT_KEYWORD, .BOOL, .OBJECT, .STRING_KEYWORD,
                     .SYMBOL_KEYWORD, .MAPPING, .ANY, .MIXED, .AUTO, .OPERATOR, .FLOAT_KEYWORD,
                     .EXCEPTION, .FUNCTION)
    }
    
    /// Checks and parses a variable declaration. If no variable
    /// declaration follows, `nil` is returned.
    ///
    /// - Returns: The AST representation of the variable declaration or `nil`.
    private mutating func parseMaybeVariable() -> ASTExpression? {
        if current.isType(.LET)                                                            ||
            ((current.isType(.IDENTIFIER) || isType(current)) && next.isType(.IDENTIFIER)) ||
            isType(current) && next.isType(.LEFT_BRACKET, .STAR, .RIGHT_BRACKET)           ||
            (isType(current) && next.isType(.LEFT_PAREN, .RIGHT_PAREN))                    ||
            isType(current) && next.isType(.LESS, .STRING, .GREATER)                       ||
            isType(current) && next.isType(.PIPE) {
            return parseFancyVariableDeclaration()
        }
        
        return nil
    }
    
    /// Parses a fancy variable declaration. `let` declarations do not need a type
    /// declaration.
    ///
    /// - Returns: The AST representation of the variable declaration.
    private mutating func parseFancyVariableDeclaration() -> ASTExpression {
        let variable: ASTExpression
        
        if current.isType(.LET) {
            let begin = current.begin
            advance()
            
            let name = parseName()
            let type: ASTExpression?
            if current.isType(.COLON) {
                advance()
                type = parseType()
            } else if next.isType(.ASSIGNMENT) && (current.isType(.IDENTIFIER) || isType(current)) {
                let missing = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'", expected: .COLON)
                type = combine(parseType(), missing)
            } else {
                type = nil
            }
            variable = ASTVariableDefinition(begin: begin, end: type?.end ?? name.end, modifiers: [], type: type, name: name)
        } else {
            let type = parseType()
            let name = parseName()
            
            variable = ASTVariableDefinition(begin: type.begin, end: name.end, modifiers: [], type: type, name: name)
        }
        
        let toReturn: ASTExpression
        if current.isType(.ASSIGNMENT) {
            advance()
            toReturn = ASTOperation(lhs: variable, rhs: parseExpression(), operatorType: .ASSIGNMENT)
        } else {
            toReturn = variable
        }
        return toReturn
    }
    
    /// Parses an expression surrounded by parentheses.
    ///
    /// - Returns: The AST reresentation of the parenthesized expression.
    private mutating func parseParenthesizedExpression() -> ASTExpression {
        var parts: [ASTExpression] = []
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '('",
                                    expected: .LEFT_PAREN))
        } else {
            advance()
        }
        let expression = parseExpression()
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing ')'",
                                    expected: .RIGHT_PAREN))
        } else {
            advance()
        }
        
        if !parts.isEmpty {
            return combine(expression, parts)
        }
        return expression
    }
    
    /// Parses an `if` statement. It can optionally be followed by
    /// an `else` statement.
    ///
    /// - Returns: The representation of the full `if` statement.
    private mutating func parseIf() -> ASTExpression {
        let begin = current.begin
        
        advance()
        
        let condition   = parseParenthesizedExpression()
        let instruction = parseInstruction()
        
        let elseInstruction: ASTExpression?
        if current.isType(.ELSE) {
            advance()
            elseInstruction = parseInstruction()
        } else {
            elseInstruction = nil
        }
        
        return ASTIf(begin: begin, condition: condition, instruction: instruction, elseInstruction: elseInstruction)
    }
    
    /// Parses a `while` statement.
    ///
    /// - Returns: The AST representation of the full `while` statement.
    private mutating func parseWhile() -> ASTExpression {
        let begin = current.begin
        
        advance()
        
        let condition = parseParenthesizedExpression()
        let body      = parseInstruction()
        
        return ASTWhile(begin: begin, condition: condition, body: body)
    }
    
    /// Parses a `foreach` statement.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseForEach() -> ASTExpression {
        var parts = [ASTExpression]()
        let begin = current.begin
        
        advance()
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '('",
                                    expected: .LEFT_PAREN))
        } else {
            advance()
        }
        let variable = parseMaybeVariable() ?? combine(ASTVariableDefinition(begin:     previous.end,
                                                                             end:       current.begin,
                                                                             modifiers: [],
                                                                             type:      nil,
                                                                             name:      combine(ASTName(begin:  previous.end,
                                                                                                        end:    current.begin),
                                                                                                ASTMissing(begin:    previous.end,
                                                                                                           end:      current.begin,
                                                                                                           message:  "Missing variable",
                                                                                                           expected: .VARIABLE_DEFINITION))),
                                                       ASTMissing(begin:    previous.end,
                                                                  end:      current.begin,
                                                                  message:  "Missing variable",
                                                                  expected: .VARIABLE_DEFINITION))
        if !current.isType(.COLON) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'", expected: .COLON))
        } else {
            advance()
        }
        let expression: ASTExpression
        if current.isType(.RIGHT_PAREN) {
            expression = ASTMissing(begin: previous.end, end: current.begin, message: "Missing expression", expected: nil)
            advance()
        } else {
            expression = parseExpression()
            if !current.isType(.RIGHT_PAREN) {
                parts.append(ASTMissing(begin:    previous.end,
                                        end:      current.begin,
                                        message:  "Missing ')'",
                                        expected: .RIGHT_PAREN))
            } else {
                advance()
            }
        }
        let loop = ASTForEach(begin: begin, variable: variable, rangeExpression: expression, body: parseInstruction())
        if !parts.isEmpty {
            return combine(loop, parts)
        }
        return loop
    }
    
    /// Parses a `for` statement.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseFor() -> ASTExpression {
        var parts: [ASTExpression] = []
        let begin = current.begin
        
        advance()
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing '('",
                                    expected: .LEFT_PAREN))
        } else {
            advance()
        }
        let initExpression = assertSemicolon(for: parseMaybeVariable() ?? parseExpression())
        let condition      = assertSemicolon(for: parseExpression())
        let after          = parseExpression()
        
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing ')'",
                                    expected: .RIGHT_PAREN))
        } else {
            advance()
        }
        let loop = ASTFor(begin: begin, initExpression: initExpression, condition: condition, afterExpression: after, body: parseInstruction())
        if !parts.isEmpty {
            return combine(loop, parts)
        }
        return loop
    }
    
    /// Parses a `switch` statement.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseSwitch() -> ASTExpression {
        let begin = current.begin
        
        advance()
        
        let variable = parseParenthesizedExpression()
        
        let part: ASTExpression?
        if !current.isType(.LEFT_CURLY) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing '{'", expected: .LEFT_CURLY)
        } else {
            part = nil
            advance()
        }
        
        let defCase  = ASTEmpty(previous.end, current.begin)
        var lastCase: ASTExpression = defCase
        var lastCaseExpressions: [ASTExpression] = []
        var cases: [ASTExpression] = []
        
        var lastToken = Parser.startToken
        while !current.isType(.RIGHT_CURLY, .EOF) {
            if current == lastToken {
                lastCaseExpressions.append(ASTWrong(token: current, message: "Unexpected token 6", expected: nil))
                advance()
                continue
            } else {
                lastToken = current
            }
            if current.isType(.CASE) {
                if lastCase !== defCase || !lastCaseExpressions.isEmpty {
                    cases.append(ASTCase(caseStatement: lastCase, expressions: lastCaseExpressions))
                }
                
                advance()
                
                lastCase = parseExpression()
                if !current.isType(.COLON) {
                    lastCase = combine(lastCase, ASTMissing(begin:    previous.end,
                                                            end:      current.begin,
                                                            message:  "Missing ':'",
                                                            expected: .COLON))
                } else {
                    advance()
                }
                lastCaseExpressions = []
            } else if current.isType(.DEFAULT) {
                cases.append(ASTCase(caseStatement: lastCase, expressions: lastCaseExpressions))
                
                lastCase = ASTDefault(current)
                advance()
                if !current.isType(.COLON) {
                    lastCase = combine(lastCase, ASTMissing(begin:    previous.end,
                                                            end:      current.begin,
                                                            message:  "Missing ':'",
                                                            expected: .COLON))
                } else {
                    advance()
                }
                lastCaseExpressions = []
            } else {
                lastCaseExpressions.append(parseInstruction())
            }
        }
        if lastCase !== defCase || !lastCaseExpressions.isEmpty {
            cases.append(ASTCase(caseStatement: lastCase, expressions: lastCaseExpressions))
        }
        
        advance()
        let toReturn = ASTSwitch(begin: begin, end: previous.end, variableExpression: variable, cases: cases)
        if let part {
            return combine(toReturn, part)
        }
        return toReturn
    }
    
    /// Parses a `do-while` statement.
    ///
    /// - Returns: The AST representation of the full `do-while` statement.
    private mutating func parseDo() -> ASTExpression {
        let begin = current.begin
        
        advance()
        
        let instruction = parseInstruction()
        
        let part: ASTExpression?
        if !current.isType(.WHILE) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing 'while'", expected: .WHILE)
        } else {
            part = nil
            advance()
        }
        let condition = parseParenthesizedExpression()
        
        let loop = ASTWhile(begin: begin, condition: condition, body: instruction)
        if let part {
            return combine(loop, part)
        }
        return loop
    }
    
    /// Parses a `break` statement.
    ///
    /// - Returns: The AST representation of the statement.
    private mutating func parseBreak() -> ASTExpression {
        let b = ASTBreak(token: current)
        advance()
        return assertSemicolon(for: b)
    }
    
    /// Parses a `continue` statement.
    ///
    /// - Returns: The AST representation of the statement.
    private mutating func parseContinue() -> ASTExpression {
        let c = ASTContinue(current)
        advance()
        return assertSemicolon(for: c)
    }
    
    /// Parses a `return` statement.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseReturn() -> ASTExpression {
        let toReturn: ASTExpression
        
        advance()
        if !current.isType(.SEMICOLON) {
            toReturn = ASTReturn(begin: previous.begin, returned: parseExpression(), end: previous.end)
        } else {
            toReturn = ASTReturn(begin: previous.begin, returned: nil, end: current.end)
        }
        
        return toReturn
    }
    
    /// Parses a `try-catch` block. The catch block can have a
    /// reference to the caught object.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseTryCatch() -> ASTExpression {
        var parts: [ASTExpression] = []
        let begin = current.begin
        
        advance()
        
        let toTry = parseInstruction()
        if !current.isType(.CATCH) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing 'catch'", expected: .CATCH))
        } else {
            advance()
        }
        
        let lp: (Int, Int)?
        if current.isType(.LEFT_PAREN) {
            advance()
            lp = nil
        } else {
            lp = (previous.end, current.begin)
        }
        let exception = parseMaybeVariable()
        if lp == nil && exception == nil {
            parts.append(ASTMissing(begin:    previous.end,
                                    end:      current.begin,
                                    message:  "Missing exception variable",
                                    expected: .VARIABLE_DEFINITION))
        }
        if exception != nil || lp == nil {
            if let lp {
                parts.append(ASTMissing(begin: lp.0, end: lp.1, message: "Missing '('", expected: .LEFT_PAREN))
            }
            if !current.isType(.RIGHT_PAREN) {
                parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'", expected: .RIGHT_PAREN))
            } else {
                advance()
            }
        }
        let caught = parseInstruction()
        
        let tryCatch = ASTTryCatch(begin: begin, tryExpression: toTry, catchExression: caught, exceptionVariable: exception)
        if !parts.isEmpty {
            return combine(tryCatch, parts)
        }
        return tryCatch
    }
    
    /// Parses an instruction.
    ///
    /// - Returns: The parsed instruction.
    private mutating func parseInstruction() -> ASTExpression {
        let toReturn: ASTExpression
        
        let maybeVariable = parseMaybeVariable()
        if let maybeVariable {
            return assertSemicolon(for: maybeVariable)
        }
        switch current.type {
        case .LEFT_CURLY: toReturn = parseBlock()
        case .IF:         toReturn = parseIf()
        case .WHILE:      toReturn = parseWhile()
        case .FOR:        toReturn = parseFor()
        case .FOREACH:    toReturn = parseForEach()
        case .SWITCH:     toReturn = parseSwitch()
        case .DO:         toReturn = parseDo()
        case .BREAK:      toReturn = parseBreak()
        case .CONTINUE:   toReturn = parseContinue()
        case .RETURN:     toReturn = assertSemicolon(for: parseReturn())
        case .TRY:        toReturn = parseTryCatch()
        case .SEMICOLON:  toReturn = assertSemicolon(for: ASTEmpty(current.begin, current.end))
        default:          toReturn = assertSemicolon(for: parseExpression())
        }
        
        return toReturn
    }
    
    /// Parses a block.
    ///
    /// - Returns: The parsed block.
    private mutating func parseBlock() -> ASTExpression {
        var expressions: [ASTExpression] = []
        
        let begin = current.begin
        
        if !current.isType(.LEFT_CURLY) {
            expressions.append(ASTMissing(begin:    previous.end,
                                          end:      current.begin,
                                          message:  "Missing '{'",
                                          expected: .LEFT_CURLY))
        } else {
            advance()
        }
        
        var lastToken = Parser.startToken
        while !current.isType(.RIGHT_CURLY, .EOF) {
            if current == lastToken {
                expressions.append(ASTWrong(token: current, message: "Unexpected token 2", expected: nil))
                advance()
                continue
            } else {
                lastToken = current
            }
            expressions.append(parseInstruction())
        }
        
        if current.isType(.EOF) {
            expressions.append(ASTMissing(begin:    previous.end,
                                          end:      current.begin,
                                          message:  "Missing '}'",
                                          expected: .RIGHT_CURLY))
        } else {
            advance()
        }
        return ASTBlock(begin: begin, end: previous.end, body: expressions)
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
    private func combine(_ main: ASTExpression, _ parts: ASTExpression...) -> ASTExpression {
        combine(main, parts as [ASTExpression])
    }
    
    /// Combines the given expressions.
    ///
    /// - Parameter main: The main expression.
    /// - Parameter parts: The parts to complete the main expression.
    /// - Returns: An `ASTCombination` of the given expressions.
    private func combine(_ main: ASTExpression, _ parts: [ASTExpression]) -> ASTExpression {
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
            toReturn = combine(expression, ASTMissing(begin:    previous.end,
                                                      end:      current.begin,
                                                      message:  "Missing ';'",
                                                      expected: .SEMICOLON))
        } else {
            advance()
            toReturn = expression
        }
        
        return toReturn
    }
    
    /// Parses a simple expression.
    ///
    /// - Parameter priority: The priority of the statement.
    /// - Returns: The AST representation of the simple expression.
    private mutating func parseSimpleExpression(priority: Int) -> ASTExpression {
        let toReturn: ASTExpression
        
        switch current.type {
        case .IDENTIFIER:
            switch next.type {
            case .LEFT_PAREN:
                let name = ASTName(token: current)
                advance(count: 2)
                
                let arguments = parseCallArguments(until: .RIGHT_PAREN)
                
                let part: ASTExpression?
                if !current.isType(.RIGHT_PAREN) {
                    part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'", expected: .RIGHT_PAREN)
                } else {
                    part = nil
                    advance()
                }
                let f = ASTFunctionCall(name: name, arguments: arguments, end: previous.end)
                if let part {
                    toReturn = combine(f, part)
                } else {
                    toReturn = f
                }
                
            case .ASSIGNMENT,
                 .ASSIGNMENT_PLUS,
                 .ASSIGNMENT_STAR,
                 .ASSIGNMENT_MINUS,
                 .ASSIGNMENT_SLASH,
                 .ASSIGNMENT_PERCENT,
                 .ASSIGNMENT_BIT_OR,
                 .ASSIGNMENT_BIT_AND,
                 .ASSIGNMENT_BIT_XOR,
                 .ASSIGNMENT_L_SHIFT,
                 .ASSIGNMENT_R_SHIFT:
                let name = ASTName(token: current)
                let type = next.type
                advance(count: 2)
                toReturn = ASTOperation(lhs: name, rhs: parseExpression(), operatorType: type)
                
            case .INCREMENT,
                 .DECREMENT:
                advance()
                toReturn = ASTUnaryOperation(begin: previous.begin, operatorType: current.type, identifier: ASTName(token: previous))
                advance()
                
            default:
                toReturn = ASTName(token: current)
                advance()
            }
            
        case .SCOPE: toReturn = ASTUnaryOperation(begin: current.begin, operatorType: .SCOPE, identifier: parseFunctionCall())
            
        case .STAR:
            advance()
            toReturn = ASTUnaryOperation(begin: previous.begin, operatorType: previous.type, identifier: parseExpression(priority: 1))
            
        case .TRUE, .FALSE: toReturn = ASTBool(token: current);      advance()
        case .NIL:          toReturn = ASTNil(token: current);       advance()
        case .THIS:         toReturn = ASTThis(token: current);      advance()
        case .SYMBOL:       toReturn = ASTSymbol(token: current);    advance()
        case .INTEGER:      toReturn = ASTInteger(token: current);   advance()
        case .FLOAT:        toReturn = ASTFloat(token: current);     advance()
        case .CHARACTER:    toReturn = ASTCharacter(token: current); advance()
        case .ELLIPSIS,
             .RANGE,
             .DOT:          toReturn = parseEllipsis()
        case .NEW:          toReturn = parseNew()
        case .STRING:       toReturn = parseStrings()
        case .LEFT_CURLY:   toReturn = parseArray()
        case .LEFT_BRACKET: toReturn = parseMapping()
            
        case .LEFT_PAREN:
            advance()
            
            let cast = parseMaybeCast(priority: priority)
            if let cast {
                toReturn = cast
            } else {
                let expression = parseExpression()
                if !current.isType(.RIGHT_PAREN) {
                    toReturn = combine(expression, ASTMissing(begin:    previous.end,
                                                              end:      current.begin,
                                                              message:  "Missing ')'",
                                                              expected: .RIGHT_PAREN))
                } else {
                    advance()
                    toReturn = expression
                }
            }
                        
        default: toReturn = ASTMissing(begin: previous.end, end: current.begin, message: "Missing expression", expected: nil)
        }
        
        return toReturn
    }
    
    /// Parses an ellipsis.
    ///
    /// - Returns: The AST representation of the read ellipsis.
    private mutating func parseEllipsis() -> ASTExpression {
        let ellipsis = ASTEllipsis(current)
        
        advance()
        if !previous.isType(.ELLIPSIS) {
            return combine(ellipsis, ASTWrong(token: previous, message: "Expected '...'", expected: .ELLIPSIS))
        }
        return ellipsis
    }
    
    /// Parses a new statement.
    ///
    /// - Returns: The AST representation of the full new statement.
    private mutating func parseNew() -> ASTExpression {
        advance()
        
        var parts: [ASTExpression] = []
        let begin = previous.begin
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '('", expected: .LEFT_PAREN))
        } else {
            advance()
        }
        let instancingExpression = parseExpression()
        
        let arguments: [ASTExpression]
        if !current.isType(.RIGHT_PAREN) {
            if !current.isType(.COMMA) {
                parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ','", expected: .COMMA))
            } else {
                advance()
            }
            arguments = parseCallArguments(until: .RIGHT_PAREN)
            if !current.isType(.RIGHT_PAREN) {
                parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'", expected: .RIGHT_PAREN))
            } else {
                advance()
            }
        } else {
            arguments = []
            advance()
        }
        let result = ASTNew(begin: begin, end: previous.end, instancingExpression: instancingExpression, arguments: arguments)
        if !parts.isEmpty {
            return combine(result, parts)
        }
        return result
    }
    
    /// Parses an array expression.
    ///
    /// - Returns: The AST representation of the array expression.
    private mutating func parseArray() -> ASTExpression {
        let begin = current.begin
        advance()
        
        let args = parseCallArguments(until: .RIGHT_CURLY)
        
        let part: ASTExpression?
        if !current.isType(.RIGHT_CURLY) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing '}'", expected: .RIGHT_CURLY)
        } else {
            part = nil
            advance()
        }
        
        let array = ASTArray(begin: begin, end: previous.end, content: args)
        if let part {
            return combine(array, part)
        }
        return array
    }
    
    /// Parses a mapping expression.
    ///
    /// - Returns: The AST representation of the mapping expression.
    private mutating func parseMapping() -> ASTExpression {
        let begin = current.begin
        advance()
        
        let args = parseCallArguments(until: .RIGHT_BRACKET)
        
        let part: ASTExpression?
        if !current.isType(.RIGHT_BRACKET) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ']'", expected: .RIGHT_BRACKET)
        } else {
            part = nil
            advance()
        }
        
        let mapping = ASTMapping(begin: begin, end: previous.end, content: args)
        if let part {
            return combine(mapping, part)
        }
        return mapping
    }
    
    /// Parses a cast statement if the streamed token represent one.
    /// Returns `nil` if the next tokens do not represent a cast
    /// statement.
    ///
    /// - Parameter priority: The priority to be used to parse the statement.
    /// - Returns: Either the AST representation of the cast expression or `nil`
    private mutating func parseMaybeCast(priority: Int) -> ASTExpression? {
        if (next.isType(.RIGHT_PAREN) && (isType(current) || current.isType(.IDENTIFIER))) ||
            (isType(current) && next.isType(.LEFT_PAREN, .LEFT_BRACKET, .RIGHT_BRACKET, .STAR)) ||
            (isType(current) && next.isType(.LESS, .STRING, .GREATER)) {
            return parseCast(priority: priority)
        }
        return nil
    }
    
    /// Parses a cast statment.
    ///
    /// - Parameter priority: The priority to be used to parse the statement.
    /// - Returns: The AST representation of the cast statement.
    private mutating func parseCast(priority: Int) -> ASTExpression {
        let begin = current.begin
        let type  = parseType()
        
        let part: ASTExpression?
        if !current.isType(.RIGHT_PAREN) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'", expected: .RIGHT_PAREN)
        } else {
            part = nil
            advance()
        }
        
        let expression = parseExpression(priority: priority)
        let cast       = ASTCast(begin: begin, castType: type, castExpression: expression)
        
        if let part {
            return combine(cast, part)
        }
        return cast
    }
    
    /// Parses the comma separated call arguments until the given end type
    /// is reached.
    ///
    /// - Parameter type: The end type.
    /// - Returns: A list with the AST representations of the parsed arguments.
    private mutating func parseCallArguments(until type: TokenType) -> [ASTExpression] {
        var list: [ASTExpression] = []
        
        var lastToken = Parser.startToken
        while !current.isType(type, .EOF, .SEMICOLON) {
            if current == lastToken {
                list.append(ASTWrong(token: current, message: "Unexpected token 4", expected: nil))
                advance()
                continue
            } else {
                lastToken = current
            }
            list.append(parseExpression())
            if !current.isType(.COMMA, type) {
                list.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ','", expected: .COMMA))
            } else if current.isType(.COMMA) {
                advance()
            }
        }
        if previous.isType(.COMMA) {
            list.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing expression", expected: nil))
        }
        
        return list
    }
    
    /// Parses a function call.
    ///
    /// - Returns: The AST representation of the function call.
    private mutating func parseFunctionCall() -> ASTExpression {
        let toReturn: ASTExpression
        
        var parts: [ASTExpression] = []
        
        advance()
        
        let name = parseName()
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '('", expected: .LEFT_PAREN))
        } else {
            advance()
        }
        
        let arguments = parseCallArguments(until: .RIGHT_PAREN)
        
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'", expected: .RIGHT_PAREN))
        } else {
            advance()
        }
        
        toReturn = ASTFunctionCall(name: name, arguments: arguments, end: previous.end)
        
        if !parts.isEmpty {
            return combine(toReturn, parts)
        }
        return toReturn
    }
    
    /// Parses a subscript expression.
    ///
    /// - Parameter priority: The prioritiy used to parse the statement.
    /// - Returns: The AST representation of the subscript.
    private mutating func parseSubscript(priority: Int) -> ASTExpression {
        let toReturn: ASTExpression
        
        advance()
        
        let expression = parseExpression()
        if current.isType(.RANGE) {
            advance()
            let rhs = parseExpression()
            
            let result = ASTOperation(lhs: expression, rhs: rhs, operatorType: .RANGE)
            if !current.isType(.RIGHT_BRACKET) {
                toReturn = ASTSubscript(expression: combine(result, ASTMissing(begin:    previous.end,
                                                                               end:      current.begin,
                                                                               message:  "Missing ']'",
                                                                               expected: .RIGHT_BRACKET)))
            } else {
                advance()
                toReturn = ASTSubscript(expression: result)
            }
        } else {
            let part: ASTExpression?
            if !current.isType(.RIGHT_BRACKET) {
                part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ']'", expected: .RIGHT_BRACKET)
            } else {
                advance()
                part = nil
            }
            
            let result: ASTExpression
            if let part {
                result = combine(ASTSubscript(expression: expression), part)
            } else {
                result = ASTSubscript(expression: expression)
            }
            
            if current.isType(.ASSIGNMENT) {
                advance()
                let rhs = parseExpression(priority: priority)
                toReturn = ASTOperation(lhs: result, rhs: rhs, operatorType: .ASSIGNMENT)
            } else {
                toReturn = result
            }
        }
        
        return toReturn
    }
    
    /// Parses a ternary.
    ///
    /// - Returns: The AST representation of the ternary.
    private mutating func parseTernary() -> ASTExpression {
        advance()
        
        let truePart = parseExpression(priority: 12)
        
        let part: ASTExpression?
        if !current.isType(.COLON) {
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'", expected: .COLON)
        } else {
            part = nil
            advance()
        }
        
        let falsePart = parseExpression(priority: 12)
        
        let toReturn = ASTOperation(lhs: truePart, rhs: falsePart, operatorType: .COLON)
        
        if let part {
            return combine(toReturn, part)
        }
        return toReturn
    }
    
    private mutating func parseScopeChain() -> ASTExpression {
        var names = [ASTExpression]()
        let begin = current.begin
        repeat {
            advance()
            names.append(parseName())
        } while current.isType(.SCOPE) && !current.isType(.EOF)
        return ASTScopeChain(begin: begin, end: previous.end, names: names)
    }
    
    /// Parses an operation.
    ///
    /// - Parameter priority: The priority used to arse the operation.
    /// - Returns: The AST representation of the operation.
    private mutating func parseOperation(priority: Int) -> ASTExpression? {
        if priority >= 1 && current.isType(.DOT, .ARROW) {
            return parseFunctionCall()
        } else if priority >= 1 && current.isType(.SCOPE) {
            return parseScopeChain()
        } else if current.isType(.LEFT_BRACKET) {
            return parseSubscript(priority: priority)
        } else if priority >= 13 && current.isType(.QUESTION) {
            return parseTernary()
        } else if priority >= 13 && current.isType(.DOUBLE_QUESTION) {
            advance()
            return parseExpression(priority: 12)
        } else if priority >= 12 && current.isType(.OR) {
            advance()
            return parseExpression(priority: 11)
        } else if priority >= 11 && current.isType(.AND) {
            advance()
            return parseExpression(priority: 10)
        } else if priority >= 10 && current.isType(.PIPE) {
            advance()
            return parseExpression(priority: 9)
        } else if priority >= 10 && current.isType(.BIT_XOR) {
            advance()
            return parseExpression(priority: 9)
        } else if priority >= 8 && current.isType(.AMPERSAND) {
            advance()
            return parseExpression(priority: 7)
        } else if priority >= 5 && current.isType(.LEFT_SHIFT, .RIGHT_SHIFT) {
            advance()
            return parseExpression(priority: 4)
        } else if priority >= 7 && current.isType(.EQUALS, .NOT_EQUAL) {
            advance()
            return parseExpression(priority: 6)
        } else if priority >= 6 && current.isType(.LESS, .LESS_OR_EQUAL, .GREATER, .GREATER_OR_EQUAL) {
            advance()
            return parseExpression(priority: 6)
        } else if priority >= 4 && current.isType(.MINUS, .PLUS) {
            advance()
            return parseExpression(priority: 3)
        } else if priority >= 3 && current.isType(.SLASH, .PERCENT, .STAR) {
            advance()
            return parseExpression(priority: 2)
        } else if priority >= 2 && current.isType(.IS) {
            advance()
            return parseType()
        }
        
        return nil
    }
    
    /// Parses a normal expression,
    ///
    /// - Returns: The parsed expression.
    private mutating func parseExpression(priority: Int = 99) -> ASTExpression {
        let lhs: ASTExpression
        
        if current.isType(.AMPERSAND) {
            if !next.isType(.IDENTIFIER) {
                lhs = ASTUnaryOperation(begin: current.begin, operatorType: .AMPERSAND,
                                        identifier: combine(ASTName(begin: current.end, end: next.begin),
                                                            ASTMissing(begin:    current.end,
                                                                       end:      next.begin,
                                                                       message:  "Missing identifier",
                                                                       expected: .IDENTIFIER)))
            } else {
                advance()
                lhs = ASTUnaryOperation(begin: previous.begin, operatorType: .AMPERSAND, identifier: ASTName(token: current))
                advance()
            }
        } else if current.isType(.STAR) {
            advance()
            lhs = ASTUnaryOperation(begin: previous.begin, operatorType: .STAR, identifier: parseExpression(priority: 1))
        } else if priority >= 2 && current.isType(.PLUS, .MINUS, .SIZEOF, .NOT, .BIT_NOT) {
            let copy = current
            advance()
            let sizeOfLP: Bool
            if copy.isType(.SIZEOF) && current.isType(.LEFT_PAREN) {
                advance()
                sizeOfLP = true
            } else {
                sizeOfLP = false
            }
            let expression = parseExpression(priority: 1)
            if copy.isType(.SIZEOF) && current.isType(.RIGHT_PAREN) && sizeOfLP {
                advance()
            }
            lhs = ASTUnaryOperation(begin: previous.begin, operatorType: copy.type, identifier: expression)
            
            if copy.isType(.PLUS) {
                return lhs
            }
        } else {
            lhs = parseSimpleExpression(priority: priority)
        }
        
        var previousExpression = lhs;
        var lastToken = Parser.startToken
        while isOperator(current) && !current.isType(.EOF) {
            if current == lastToken {
                previousExpression = combine(previousExpression, ASTWrong(token:    current,
                                                                          message:  "Unexpected token 3",
                                                                          expected: nil))
                advance()
                continue
            } else {
                lastToken = current
            }
            let opType = current.type
            if let rhs = parseOperation(priority: priority) {
                previousExpression = ASTOperation(lhs: previousExpression, rhs: rhs, operatorType: opType)
            } else {
                break
            }
        }
        return previousExpression
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
            toReturn = combine(variable, ASTMissing(begin:    previous.end,
                                                    end:      current.begin,
                                                    message:  "Missing ';'",
                                                    expected: .SEMICOLON))
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
    mutating func parse(end: TokenType = .EOF) -> [ASTExpression] {
        var expressions: [ASTExpression] = []
        
        var lastToken = Parser.startToken
        while !current.isType(.EOF) && !current.isType(end) {
            if current == lastToken {
                expressions.append(ASTWrong(token: current, message: "Unexpected token 1", expected: nil))
                advance()
                continue
            } else {
                lastToken = current
            }
            expressions.append(parseToplevelExpression())
        }
        
        return expressions
    }
}
