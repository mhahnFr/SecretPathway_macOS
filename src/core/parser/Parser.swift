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
                               ASTWrong(token: current, message: "Expected a string literal"))
        } else if current.isType(.STRING) {
            let begin   = previous.begin
            let strings = parseStrings()
            
            toReturn = assertSemicolon(for: ASTInheritance(begin: begin, end: (current.isType(.SEMICOLON) ? current : previous).end, inherited: strings))
        } else if !current.isType(.SEMICOLON) && !next.isType(.SEMICOLON) {
            toReturn = combine(ASTInheritance(begin: previous.begin, end: previous.end, inherited: nil),
                               ASTMissing(begin: previous.end, end: current.begin, message: "Expected ';'"))
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
                   ASTMissing(begin: previous.end, end: current.begin, message: "Expected a string literal"))
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
                                      ASTWrong(token: current, message: "Expected a string literal"))
            }
            return assertSemicolon(for: ASTClass(begin: begin, name: name, inheritance: inheritance))
        } else if !current.isType(.LEFT_CURLY) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '{'"))
        } else {
            advance()
        }
        
        let statements = parse(end: .RIGHT_CURLY)
        if !current.isType(.RIGHT_CURLY) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '}'"))
        } else {
            advance()
        }
        if !current.isType(.SEMICOLON) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ';'"))
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
        token.isType(.PRIVATE, .PROTECTED, .PUBLIC, .DEPRECATED, .OVERRIDE, .NOSAVE)
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
                                        ASTWrong(token: current, message: "Expected a modifier")))
            } else {
                break
            }
            advance()
        }
        
        return toReturn
    }
    
    /// Parses a type.
    ///
    /// - Returns: The parsed type.
    private mutating func parseType() -> ASTExpression {
        // TODO: Implement type system
        fatalError()
    }
    
    /// Parses a name.
    ///
    /// - Returns: The parsed name.
    private mutating func parseName() -> ASTExpression {
        let toReturn: ASTExpression
        
        if isStopToken(current) {
            toReturn = combine(ASTName(begin: previous.end, end: current.begin),
                               ASTMissing(begin: previous.end, end: current.begin, message: "Missing name"))
        } else if current.isType(.OPERATOR) {
            let begin = current.begin
            advance()
            
            let part: ASTExpression?
            if !isOperator(current) {
                part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing operator")
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
        } else if !current.isType(.IDENTIFIER) {
            toReturn = combine(ASTName(begin: current.begin, end: current.end),
                               ASTWrong(token: current, message: "Expected a name"))
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
                if current.isType(.ELLIPSIS) || next.isType(.RIGHT_PAREN, .LEFT_CURLY) {
                    toReturn.append(ASTEllipsis(current))
                    if next.isType(.LEFT_CURLY) {
                        toReturn.append(ASTMissing(begin: current.end, end: next.begin, message: "Expected ')'"))
                        advance()
                    } else {
                        advance(count: 2)
                    }
                    break
                }
                
                let type = parseType()
                
                let name: ASTExpression
                if !current.isType(.IDENTIFIER) {
                    if current.isType(.COMMA, .RIGHT_PAREN) {
                        name = combine(ASTName(begin: previous.end, end: current.begin),
                                       ASTMissing(begin: previous.end, end: current.begin, message: "Parameter's name missing"))
                    } else {
                        name = combine(ASTName(begin: current.begin, end: current.end),
                                       ASTWrong(token: current, message: "Expected parameter's name"))
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
                        toReturn.append(ASTMissing(begin: previous.end, end: current.begin, message: "Expected ')'"))
                    } else {
                        advance()
                    }
                } else if !current.isType(.COMMA) {
                    toReturn.append(ASTMissing(begin: previous.end, end: current.begin, message: "Expected ','"))
                } else {
                    advance()
                }
            } while !stop && !current.isType(.EOF)
        } else {
            advance()
        }
        
        return toReturn
    }
    
    /// Returns whether the given token is a stop token.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token should stop a parsing loop.
    private func isStopToken(_ token: Token) -> Bool {
        token.isType(.EOF, .RIGHT_PAREN, .RIGHT_BRACKET, .RIGHT_CURLY, .COLON, .SEMICOLON,
                     .ASSIGNMENT, .ASSIGNMENT_PLUS, .ASSIGNMENT_STAR, .ASSIGNMENT_MINUS,
                     .ASSIGNMENT_SLASH, .ASSIGNMENT_PERCENT, .ELSE, .WHILE, .CATCH)
    }
    
    /// Returns whether the given type represents an operator.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token represents an operator.
    private func isOperator(_ token: Token) -> Bool {
        token.isType(.DOT, .ARROW, .PIPE, .LEFT_SHIFT, .RIGHT_SHIFT, .DOUBLE_QUESTION, .QUESTION,
                     .PLUS, .MINUS, .STAR, .SLASH, .PERCENT, .LESS, .LESS_OR_EQUAL, .GREATER, .IS,
                     .GREATER_OR_EQUAL, .EQUALS, .NOT_EQUAL, .AMPERSAND, .AND, .OR, .LEFT_BRACKET)
    }
    
    /// Returns whether the given token represents a type.
    ///
    /// - Parameter token: The token to be checked.
    /// - Returns: Whether the given token represents a type.
    private func isType(_ token: Token) -> Bool {
        token.isType(.VOID, .CHAR_KEYWORD, .INT_KEYWORD, .BOOL, .OBJECT, .STRING_KEYWORD,
                     .SYMBOL_KEYWORD, .MAPPING, .ANY, .MIXED, .AUTO, .OPERATOR)
    }
    
    /// Checks and parses a variable declaration. If no variable
    /// declaration follows, `nil` is returned.
    ///
    /// - Returns: The AST representation of the variable declaration or `nil`.
    private mutating func parseMaybeVariable() -> ASTExpression? {
        if current.isType(.LET)                                                            ||
            ((current.isType(.IDENTIFIER) || isType(current)) && next.isType(.IDENTIFIER)) ||
            isType(current) && next.isType(.LEFT_BRACKET, .STAR, .RIGHT_BRACKET)           ||
            (isType(current) && isStopToken(next))                                         ||
            (isType(current) && next.isType(.LEFT_PAREN, .RIGHT_PAREN)) {
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
                let missing = ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'")
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
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '('"))
        } else {
            advance()
        }
        let expression = parseExpression()
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'"))
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
    
    /// Parses a `for` statement. `foreach` loops are parsed by this
    /// method as well.
    ///
    /// - Returns: The AST representation of the full statement.
    private mutating func parseFor() -> ASTExpression {
        var parts: [ASTExpression] = []
        let begin = current.begin
        
        advance()
        
        if !current.isType(.LEFT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '('"))
        } else {
            advance()
        }
        var variable = parseMaybeVariable()
        if variable != nil {
            if current.isType(.COLON) {
                advance()
                let expression = parseExpression()
                if !current.isType(.RIGHT_PAREN) {
                    parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'"))
                } else {
                    advance()
                }
                let loop = ASTForEach(begin: begin, variable: variable!, rangeExpression: expression, body: parseInstruction())
                if !parts.isEmpty {
                    return combine(loop, parts)
                }
                return loop
            } else {
                variable = assertSemicolon(for: variable!)
            }
        }
        let initExpression = variable ?? assertSemicolon(for: parseExpression())
        let condition      = assertSemicolon(for: parseExpression())
        let after          = parseExpression()
        
        if !current.isType(.RIGHT_PAREN) {
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'"))
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
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing '{'")
        } else {
            part = nil
            advance()
        }
        
        let defCase  = ASTEmpty(previous.end, current.begin)
        var lastCase: ASTExpression = defCase
        var lastCaseExpressions: [ASTExpression] = []
        var cases: [ASTExpression] = []
        
        while !current.isType(.RIGHT_CURLY) && !isStopToken(current) {
            if current.isType(.CASE) {
                if lastCase !== defCase || !lastCaseExpressions.isEmpty {
                    cases.append(ASTCase(caseStatement: lastCase, expressions: lastCaseExpressions))
                }
                
                advance()
                
                lastCase = parseExpression()
                if !current.isType(.COLON) {
                    lastCase = combine(lastCase, ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'"))
                } else {
                    advance()
                }
                lastCaseExpressions = []
            } else if current.isType(.DEFAULT) {
                cases.append(ASTCase(caseStatement: lastCase, expressions: lastCaseExpressions))
                
                lastCase = ASTDefault(current)
                advance()
                if !current.isType(.COLON) {
                    lastCase = combine(lastCase, ASTMissing(begin: previous.end, end: current.begin, message: "Missing ':'"))
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
            part = ASTMissing(begin: previous.end, end: current.begin, message: "Missing 'while'")
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
            parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing 'catch'"))
        } else {
            advance()
        }
        
        let exception: ASTExpression?
        if current.isType(.LEFT_PAREN, .RIGHT_PAREN) {
            if !current.isType(.LEFT_PAREN) {
                parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '('"))
            } else {
                advance()
            }
            if !current.isType(.RIGHT_PAREN) {
                exception = parseFancyVariableDeclaration()
                if !current.isType(.RIGHT_PAREN) {
                    parts.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing ')'"))
                } else {
                    advance()
                }
            } else {
                exception = nil
                advance()
            }
        } else {
            exception = nil
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
        case .LEFT_CURLY:    toReturn = parseBlock()
        case .IF:            toReturn = parseIf()
        case .WHILE:         toReturn = parseWhile()
        case .FOR, .FOREACH: toReturn = parseFor()
        case .SWITCH:        toReturn = parseSwitch()
        case .DO:            toReturn = parseDo()
        case .BREAK:         toReturn = parseBreak()
        case .CONTINUE:      toReturn = parseContinue()
        case .RETURN:        toReturn = assertSemicolon(for: parseReturn())
        case .TRY:           toReturn = parseTryCatch()
        case .SEMICOLON:     toReturn = assertSemicolon(for: ASTEmpty(current.begin, current.end))
        default:             toReturn = assertSemicolon(for: parseExpression())
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
            expressions.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '{'"))
        } else {
            advance()
        }
        
        var lastToken = Parser.startToken
        while !current.isType(.RIGHT_CURLY, .EOF) {
            if current == lastToken {
                expressions.append(ASTWrong(token: current, message: "Unexpected token 2"))
                advance()
                continue
            } else {
                lastToken = current
            }
            expressions.append(parseInstruction())
        }
        
        if current.isType(.EOF) {
            expressions.append(ASTMissing(begin: previous.end, end: current.begin, message: "Missing '}'"))
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
            toReturn = combine(expression, ASTMissing(begin: previous.end, end: current.begin, message: "Missing ';'"))
        } else {
            toReturn = expression
        }
        
        return toReturn
    }
    
    /// Parses a simple expression.
    ///
    /// - Parameter priority: The priority of the statement.
    /// - Returns: The AST representation of the simple expression.
    private mutating func parseSimpleExpression(priority: Int) -> ASTExpression {
        // TODO: Implement
        fatalError()
    }
    
    private mutating func parseFunctionCall() -> ASTExpression {
        // TODO: Implement
        fatalError()
    }
    
    private mutating func parseSubscript(priority: Int) -> ASTExpression {
        // TODO: Implement
        fatalError()
    }
    
    private mutating func parseTernary() -> ASTExpression {
        // TODO: Implement
        fatalError()
    }
    
    /// Parses an operation.
    ///
    /// - Parameter priority: The priority used to arse the operation.
    /// - Returns: The AST representation of the operation.
    private mutating func parseOperation(priority: Int) -> ASTExpression? {
        if priority >= 1 && current.isType(.DOT, .ARROW) {
            return parseFunctionCall()
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
    
    /// Parses a normal expression.
    ///
    /// - Returns: The parsed expression.
    private mutating func parseExpression() -> ASTExpression {
        return parseExpression(priority: 99)
    }
    
    /// Parses a normal expression,
    ///
    /// - Returns: The parsed expression.
    private mutating func parseExpression(priority: Int) -> ASTExpression {
        let lhs: ASTExpression
        
        if current.isType(.AMPERSAND) {
            if !next.isType(.IDENTIFIER) {
                lhs = ASTUnaryOperation(begin: current.begin, operatorType: .AMPERSAND,
                                        identifier: combine(ASTName(begin: current.end, end: next.begin),
                                                            ASTMissing(begin: current.end, end: next.begin, message: "Missing identifier")))
            } else {
                advance()
                lhs = ASTUnaryOperation(begin: previous.begin, operatorType: .AMPERSAND, identifier: ASTName(token: current))
                advance()
            }
        } else if current.isType(.STAR) {
            advance()
            lhs = ASTUnaryOperation(begin: previous.begin, operatorType: .STAR, identifier: parseExpression(priority: 1))
        } else if priority >= 2 && current.isType(.PLUS, .MINUS, .SIZEOF, .NOT) {
            let copy = current
            advance()
            if copy.isType(.SIZEOF) && current.isType(.LEFT_PAREN) {
                advance()
            }
            let expression = parseExpression(priority: 1)
            if copy.isType(.SIZEOF) && current.isType(.RIGHT_PAREN) {
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
        while isOperator(current) && !isStopToken(current) {
            if current == lastToken {
                previousExpression = combine(previousExpression, ASTWrong(token: current, message: "Unexpected token 3"))
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
