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

/// This class interprets parsed LPC source code.
class Interpreter: ASTVisitor {
    /// The highlights generated from an AST.
    private(set) var highlights: [Highlight] = []
    
    private let loader: LPCFileManager
    
    /// The currently used context object.
    private var current = Context()
    /// The return type of the lastly interpreted expression.
    private var currentType: TypeProto = InterpreterType.any
    
    init(loader: LPCFileManager) {
        self.loader = loader
    }
    
    /// Creates and returns a context object for the given AST.
    ///
    /// - Parameter ast: The AST to be interpreted.
    /// - Returns: The interpretation context.
    func createContext(for ast: [ASTExpression]) async -> Context {
        highlights = []
        current    = Context()
        
        for node in ast { await node.visit(self) }
        return current
    }
    
    /// Unwraps the given ASTCombination.
    ///
    /// - Parameters:
    ///   - combination: The ASTCombination to be unwrapped.
    ///   - type: The type of the desired AST node.
    /// - Returns: The AST node of the given type found in the combination or `nil`.
    private func unwrap<T>(combination: ASTCombination, type: T.Type) async -> T? {
        var toReturn: T? = nil
        
        for expression in combination.expressions {
            if let casted = expression as? T {
                toReturn = casted
            } else {
                await expression.visit(self)
            }
        }
        
        return toReturn
    }
    
    /// Casts the given expression to the given type.
    ///
    /// If the given expression is an ASTCombination, it is unwrapped.
    ///
    /// - Parameters:
    ///   - type: The desired type.
    ///   - expression: The expression to maybe unwrap.
    /// - Returns: The unwrapped expression or `nil`, if the given type did not match.
    private func cast<T>(type: T.Type, _ expression: ASTExpression) async -> T? {
        if let casted = expression as? T {
            return casted
        } else if let combination = expression as? ASTCombination {
            return await unwrap(combination: combination, type: type)
        }
        return nil
    }
    
    /// Adds a type mismatch highlight if the given type represents `void`.
    ///
    /// - Parameter type: The type expression to be checked.
    private func maybeWrongVoid(_ type: AbstractType) {
        if let t = type as? BasicType,
           let actualType = t.representedType,
           actualType == .VOID {
            highlights.append(MessagedHighlight(begin:   type.begin,
                                                end:     type.end,
                                                type:    .TYPE_MISMATCH,
                                                message: "'void' not allowed here"))
        }
    }
    
    /// Visits the parameters declarations of the given function declaration.
    ///
    /// - Parameter function: The declared function whose parameters to visit.
    /// - Returns: The definitions created from the declared parameters.
    private func visitParams(of function: ASTFunctionDefinition) async -> [Definition] {
        var parameters: [Definition] = []
        
        for parameter in function.parameters {
            if parameter.type == .MISSING {
                highlights.append(MessagedHighlight(begin:   parameter.begin,
                                                    end:     parameter.end,
                                                    type:    .MISSING,
                                                    message: (parameter as! ASTMissing).message))
            } else if parameter.type != .AST_ELLIPSIS,
                      let param = await cast(type: ASTParameter.self, parameter),
                      let type  = await cast(type: AbstractType.self, param.declaredType) {
                await type.visit(self)
                maybeWrongVoid(type)
                
                await parameters.append(Definition(begin:      param.begin,
                                                   returnType: type,
                                                   name:       cast(type: ASTName.self, param.name)?.name ?? "<< unknown >>",
                                                   kind:       .PARAMETER))
            }
        }
        
        return parameters
    }
    
    private func createContext(for file: ASTStrings) async -> Context? {
        return await loader.loadAndParse(file: file.value)
    }
    
    private func fileExists(file: ASTStrings) async -> Bool {
        return await loader.exists(file: file.value)
    }
    
    /// Adds the context of the file represented by the given string nodes
    /// to the current context.
    ///
    /// - Parameter file: The strings representing the file name.
    private func addIncluding(file: ASTStrings) async {
        if let context = await createContext(for: file) {
            current.included.append(context)
        } else {
            highlights.append(MessagedHighlight(begin:   file.begin,
                                                end:     file.end,
                                                type:    .ERROR,
                                                message: "Could not resolve inclusion"))
        }
    }
    
    /// Adds the context of the file represented by the given string nodes
    /// as super context to the current context.
    ///
    /// - Parameter file: The strings representing the file name.
    private func addInheriting(from file: ASTStrings) async {
        if let context = await createContext(for: file) {
            current.inherited.append(context)
        } else {
            highlights.append(MessagedHighlight(begin:   file.begin,
                                                end:     file.end,
                                                type:    .ERROR,
                                                message: "Could not resolve inheritance"))
        }
    }
    
    /// Visits the given function call.
    ///
    /// The parameter count and their types are checked against their definition.
    ///
    /// - Parameters:
    ///   - function: The function to be visited.
    ///   - id: The definition to check against.
    private func visitFunctionCall(function: ASTFunctionCall, id: FunctionDefinition) async {
        let arguments = function.arguments
        var tooManyBegin: Int?
        var it = id.parameters.makeIterator()
        var lastArg: ASTExpression?
        
        for argument in arguments {
            lastArg = argument
            await argument.visit(self)
            
            if let next = it.next() {
                if !next.returnType.isAssignable(from: currentType) {
                    highlights.append(MessagedHighlight(begin: argument.begin, end: argument.end, type: .TYPE_MISMATCH, message: "\(next.returnType.string) is not assignable from \(currentType.string)"))
                }
            } else {
                if !id.variadic && tooManyBegin == nil {
                    tooManyBegin = argument.begin
                }
            }
        }
        
        if let tooManyBegin {
            highlights.append(MessagedHighlight(begin:   tooManyBegin,
                                                end:     arguments.last!.end,
                                                type:    .ERROR,
                                                message: "Expected \(id.parameters.count) arguments, got \(arguments.count)"))
        }
        if it.next() != nil {
            highlights.append(MessagedHighlight(begin:   lastArg?.end ?? function.begin,
                                                end:     function.end,
                                                type:    .ERROR,
                                                message: "Expected \(id.parameters.count) arguments, got \(arguments.count)"))
        }
    }
    
    /// Visits the given function call.
    ///
    /// The types are checked against te given definitions.
    ///
    /// - Parameters:
    ///   - function: The function call to be visited.
    ///   - ids: The definition candidates.
    /// - Returns: The return type of the matching function definition, `nil` if no definition matches.
    private func visitFunctionCall(function: ASTFunctionCall, ids: [Definition]) async -> TypeProto? {
        for id in ids {
            if let fd = id as? FunctionDefinition,
               fd.parameters.count == function.arguments.count || fd.variadic {
                // TODO: Check types
                await visitFunctionCall(function: function, id: fd)
                return fd.returnType
            }
        }
        for id in ids {
            if let fd = id as? FunctionDefinition {
                await visitFunctionCall(function: function, id: fd)
                return fd.returnType
            }
        }
        return nil
    }
    
    /// Visits the given unary operation as a super send.
    ///
    /// - Parameter operation: The operation to be visited.
    private func visitSuperFunc(_ operation: ASTUnaryOperation) async {
        if let f = await cast(type: ASTFunctionCall.self, operation.identifier),
           let n = await cast(type: ASTName.self, f.name)?.name {
            let ids = current.getSuperIdentifiers(name: n)
            if ids.isEmpty {
                highlights.append(MessagedHighlight(begin:   operation.begin,
                                                    end:     operation.end,
                                                    type:    .NOT_FOUND,
                                                    message: "Identifier not found"))
            } else {
                currentType = await visitFunctionCall(function: f, ids: ids) ?? InterpreterType.unknown
            }
        }
    }
    
    /// Visits a name expression.
    ///
    /// - Parameters:
    ///   - context: The context in which to search for the identifier.
    ///   - name: The name expression to be resolved.
    private func visitName(context: Context, name: ASTName) {
        if let n = name.name {
            let identifiers = context.getIdentifiers(name: n, pos: context === current ? name.begin : Int.max)
            if let first = identifiers.first {
                highlights.append(Highlight(begin: name.begin,
                                            end:   name.end,
                                            type:  first.kind))
                currentType = first.returnType
            } else {
                if n.starts(with: "$") {
                    highlights.append(MessagedHighlight(begin:   name.begin,
                                                        end:     name.end,
                                                        type:    .NOT_FOUND_BUILTIN,
                                                        message: "Built-in not found"))
                } else {
                    highlights.append(MessagedHighlight(begin:   name.begin,
                                                        end:     name.end,
                                                        type:    .NOT_FOUND,
                                                        message: "Identifier not found"))
                }
                currentType = InterpreterType.unknown
            }
        }
    }
    
    private func visitNew(expression: ASTNew) async -> TypeProto {
        guard let strings = await cast(type: ASTStrings.self, expression.instancingExpression),
              let context = await loader.loadAndParse(file: strings.value) else {
            highlights.append(MessagedHighlight(begin:   expression.instancingExpression.begin,
                                                end:     expression.instancingExpression.end,
                                                type:    .ERROR,
                                                message: "Could not resolve file"))
            for argument in expression.arguments {
                await argument.visit(self)
            }
            return InterpreterType.object
        }
        let ids = context.getIdentifiers(name: "create", pos: Int.max)
        if await visitFunctionCall(function: expression, ids: ids) == nil {
            highlights.append(MessagedHighlight(begin:   expression.instancingExpression.begin,
                                                end:     expression.instancingExpression.end,
                                                type:    .WARNING,
                                                message: "No constructor found"))
            for argument in expression.arguments {
                await argument.visit(self)
            }
        }
        return InterpreterType(type: .OBJECT, file: strings.value)
    }
    
    internal func visit(_ expression: ASTExpression) async {
        var highlight = true
        
        switch expression.type {
        case .MISSING, .WRONG:
            highlights.append(MessagedHighlight(begin:   expression.begin,
                                                end:     expression.end,
                                                type:    expression.type,
                                                message: (expression as! ASTHole).message))
            highlight = false
            
        case .CAST:
            let c = expression as! ASTCast
            await c.castExpression.visit(self)
            currentType = await cast(type: AbstractType.self, c.castType)! as TypeProto
            
        case .VARIABLE_DEFINITION:
            let varDefinition = expression as! ASTVariableDefinition
            
            let type: AbstractType
            if let t = varDefinition.returnType,
               let unwrapped = await cast(type: AbstractType.self, t) {
                type = unwrapped
                await type.visit(self)
            } else {
                type = InterpreterType.unknown
            }
            
            await current.addIdentifier(begin: varDefinition.begin,
                                        name:  cast(type: ASTName.self, varDefinition.name)?.name ?? "<unknown>",
                                        type: type,
                                        .VARIABLE_DEFINITION)
            maybeWrongVoid(type)
            currentType = type
            
        case .FUNCTION_DEFINITION:
            let function         = expression as! ASTFunctionDefinition
            let block            = function.body
            let paramExpressions = function.parameters
            
            let retType = await cast(type: AbstractType.self, function.returnType)!
            await retType.visit(self)
            let params  = await visitParams(of: function)
            
            current = await current.addFunction(begin:      function.begin,
                                                scopeBegin: block.begin,
                                                name:       cast(type: ASTName.self,      function.name)!,
                                                returnType: cast(type: AbstractType.self, function.returnType)!,
                                                parameters: params,
                                                variadic:   paramExpressions.last?.type == .AST_ELLIPSIS)
            if let block = await cast(type: ASTBlock.self, block) {
                for expression in block.body {
                    await expression.visit(self)
                }
            }
            current = current.popScope(end: expression.end)!
            currentType = InterpreterType.void
            
        case .BLOCK:
            current   = current.pushScope(begin: expression.begin)
            let block = expression as! ASTBlock
            for expression in block.body { await expression.visit(self) }
            current = current.popScope(end: expression.end)!
            currentType = InterpreterType.void
            
        case .AST_INCLUDE:
            await addIncluding(file: cast(type: ASTStrings.self, (expression as! ASTInclude).included)!)
            
        case .AST_INHERITANCE:
            let inheritance = expression as! ASTInheritance
            
            if let inherited = inheritance.inherited {
                await addInheriting(from: cast(type: ASTStrings.self, inherited)!)
            } else {
                highlight = false
                highlights.append(MessagedHighlight(begin:   inheritance.begin,
                                                    end:     inheritance.end,
                                                    type:    .WARNING,
                                                    message: "Inheriting from nothing"))
            }
            
        case .FUNCTION_CALL:
            let fc = expression as! ASTFunctionCall
            
            let name = await cast(type: ASTName.self, fc.name)!
            await name.visit(self)
            if let n = name.name {
                let ids = current.getIdentifiers(name: n, pos: name.begin)
                if !ids.isEmpty {
                    currentType = await visitFunctionCall(function: fc, ids: ids) ?? InterpreterType.unknown
                }
            }
            
        case .NAME:
            visitName(context: current, name: expression as! ASTName)
            highlight = false
            
        case .UNARY_OPERATOR:
            let operation = expression as! ASTUnaryOperation
            
            if operation.operatorType == .SCOPE {
                await visitSuperFunc(operation)
            } else {
                await operation.identifier.visit(self)
            }
            
        case .OPERATION:
            let operation = expression as! ASTOperation
            let rhs       = operation.rhs
            await operation.lhs.visit(self)
            
            let lhsType = currentType
            
            if operation.operatorType == .ARROW ||
               operation.operatorType == .DOT {
                if let funcCall = await cast(type: ASTFunctionCall.self, rhs),
                   let name     = await cast(type: ASTName.self, funcCall.name),
                   let nameStr  = name.name {
                    if operation.lhs is ASTThis {
                        visitName(context: current, name: name)
                        currentType = await visitFunctionCall(function: funcCall, ids: current.getIdentifiers(name: nameStr, pos: operation.begin)) ?? InterpreterType.unknown
                    } else if let type     = lhsType as? BasicType,
                              let file     = type.typeFile as? ASTStrings,
                              let context  = await createContext(for: file) {
                        let ids = context.getIdentifiers(name: nameStr, pos: Int.max)
                        visitName(context: context, name: name)
                        currentType = await visitFunctionCall(function: funcCall, ids: ids) ?? InterpreterType.unknown
                    }
                } else {
                    currentType = InterpreterType.unknown
                }
            } else {
                await rhs.visit(self)
            }
            if operation.operatorType == .ASSIGNMENT &&
               !lhsType.isAssignable(from: currentType) {
                highlights.append(MessagedHighlight(begin:   rhs.begin,
                                                    end:     rhs.end,
                                                    type:    .TYPE_MISMATCH,
                                                    message: "\(lhsType.string) is not assignable from \(currentType.string)"))
            }
            switch operation.operatorType {
            case .IS,      .AND,
                 .EQUALS,  .NOT_EQUAL,
                 .LESS,    .LESS_OR_EQUAL,
                 .GREATER, .GREATER_OR_EQUAL: currentType = InterpreterType.bool
                
            case .RANGE, .ELLIPSIS:           currentType = InterpreterType.any
                
            case .ASSIGNMENT,      .OR,
                 .AMPERSAND,       .PIPE,
                 .LEFT_SHIFT,      .RIGHT_SHIFT,
                 .DOUBLE_QUESTION, .QUESTION,
                 .INCREMENT,       .DECREMENT,
                 .COLON,           .PLUS,
                 .MINUS,           .STAR,
                 .SLASH,           .PERCENT,
                 .ARROW,           .DOT,
                 .ASSIGNMENT_PLUS,
                 .ASSIGNMENT_MINUS,
                 .ASSIGNMENT_STAR,
                 .ASSIGNMENT_SLASH,
                 .ASSIGNMENT_PERCENT:         break
                
            default:                          currentType = InterpreterType.void
            }
            
        case .AST_IF:
            let i         = expression as! ASTIf
            let condition = i.condition
            
            await condition.visit(self)
            if !InterpreterType.bool.isAssignable(from: currentType) {
                highlights.append(MessagedHighlight(begin:   condition.begin,
                                                    end:     condition.end,
                                                    type:    .TYPE_MISMATCH,
                                                    message: "Condition should be a boolean expression"))
            }
            await i.instruction.visit(self)
            await i.elseInstruction?.visit(self)
            
        case .AST_RETURN:
            let ret      = expression as! ASTReturn
            let returned = ret.returned
            
            if let returned {
                await returned.visit(self)
            } else {
                currentType = InterpreterType.void
            }
            
            if let enclosing = current.queryEnclosingFunction(),
               !enclosing.returnType.isAssignable(from: currentType) {
                highlights.append(MessagedHighlight(begin:   ret.begin,
                                                    end:     ret.end,
                                                    type:   .TYPE_MISMATCH,
                                                    message: "\(enclosing.returnType.string) is not assignable from \(currentType.string)"))
            }
            
        case .FUNCTION_REFERENCE:
            let funcref = expression as! FunctionReferenceType
            
            await cast(type: AbstractType.self, funcref.returnType)?.visit(self)
            for parameter in funcref.parameterTypes {
                if let type = await cast(type: AbstractType.self, parameter) {
                    await type.visit(self)
                    maybeWrongVoid(type)
                }
            }
         
        case .ARRAY_TYPE:
            await cast(type: AbstractType.self, (expression as! ArrayType).underlyingType)?.visit(self)
            
        case .TYPE:
            let type = expression as! BasicType
            if let typeFile = type.typeFile as? ASTStrings,
               await !fileExists(file: typeFile) {
                highlights.append(MessagedHighlight(begin:   typeFile.begin,
                                                    end:     typeFile.end,
                                                    type:    .ERROR,
                                                    message: "Could not resolve file"))
            }
            
        case .AST_ELLIPSIS:
            let enclosing = current.queryEnclosingFunction()
            if enclosing == nil || !enclosing!.variadic {
                highlights.append(MessagedHighlight(begin:   expression.begin,
                                                    end:     expression.end,
                                                    type:    .ERROR,
                                                    message: "Enclosing function is not variadic"))
                highlight = false
            }
            currentType = InterpreterType.unknown
            
        case .AST_NEW:
            let new = expression as! ASTNew
            
            currentType = await visitNew(expression: new)
            
        case .ARRAY:
            var substituted: TypeProto?
            
            for expression in (expression as! ASTArray).content {
                await expression.visit(self)
                if let s = substituted {
                    if !s.isAssignable(from: currentType) {
                        // TODO: Find common super type
                        substituted = InterpreterType.any
                    }
                } else {
                    substituted = currentType
                }
            }
            
            if let substituted {
                currentType = InterpreterArrayType(from: substituted)
            } else {
                currentType = InterpreterArrayType.any
            }
            
        case .AST_MAPPING:
            for expression in (expression as! ASTMapping).content { await expression.visit(self) }
            currentType = InterpreterType.mapping

        case .AST_STRING,
             .STRINGS:       currentType = InterpreterType.string
        case .AST_THIS:      currentType = InterpreterType.object
        case .AST_INTEGER:   currentType = InterpreterType.int
        case .AST_NIL:       currentType = InterpreterType.object
        case .AST_SYMBOL:    currentType = InterpreterType.symbol
        case .AST_BOOL:      currentType = InterpreterType.bool
        case .AST_CHARACTER: currentType = InterpreterType.char
            
        default: currentType = InterpreterType.void
        }
        if highlight {
            highlights.append(ASTHighlight(node: expression))
        }
    }
    
    internal func visitType(_ type: ASTType) -> Bool {
        type != .BLOCK               &&
        type != .FUNCTION_DEFINITION &&
        type != .VARIABLE_DEFINITION &&
        type != .OPERATION           &&
        type != .CAST                &&
        type != .UNARY_OPERATOR      &&
        type != .AST_IF              &&
        type != .AST_RETURN          &&
        type != .FUNCTION_REFERENCE  &&
        type != .ARRAY_TYPE          &&
        type != .AST_MAPPING         &&
        type != .ARRAY               &&
        type != .FUNCTION_CALL       &&
        type != .TYPE                &&
        type != .AST_NEW
    }
}
