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
    
    /// The currently used context object.
    private var current = Context()
    /// The return type of the lastly interpreted expression.
    private var currentType: TypeProto = InterpreterType.any
    
    /// Creates and returns a context object for the given AST.
    ///
    /// - Parameter ast: The AST to be interpreted.
    /// - Returns: The interpretation context.
    func createContext(for ast: [ASTExpression]) -> Context {
        highlights = []
        current    = Context()
        
        ast.forEach { $0.visit(self) }
        return current
    }
    
    /// Unwraps the given ASTCombination.
    ///
    /// - Parameters:
    ///   - combination: The ASTCombination to be unwrapped.
    ///   - type: The type of the desired AST node.
    /// - Returns: The AST node of the given type found in the combination or `nil`.
    private func unwrap<T>(combination: ASTCombination, type: T.Type) -> T? {
        var toReturn: T? = nil
        
        for expression in combination.expressions {
            if let casted = expression as? T {
                toReturn = casted
            } else {
                expression.visit(self)
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
    private func cast<T>(type: T.Type, _ expression: ASTExpression) -> T? {
        if let casted = expression as? T {
            return casted
        } else if let combination = expression as? ASTCombination {
            return unwrap(combination: combination, type: type)
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
    private func visitParams(of function: ASTFunctionDefinition) -> [Definition] {
        var parameters: [Definition] = []
        
        for parameter in function.parameters {
            if parameter.type == .MISSING {
                highlights.append(MessagedHighlight(begin:   parameter.begin,
                                                    end:     parameter.end,
                                                    type:    .MISSING,
                                                    message: (parameter as! ASTMissing).message))
            } else if parameter.type != .AST_ELLIPSIS,
                      let param = cast(type: ASTParameter.self, parameter),
                      let type  = cast(type: AbstractType.self, param.declaredType) {
                type.visit(self)
                maybeWrongVoid(type)
                
                parameters.append(Definition(begin:      param.begin,
                                             returnType: type,
                                             name:       cast(type: ASTName.self, param.name)?.name ?? "<< unknown >>",
                                             kind:       .PARAMETER))
            }
        }
        
        return parameters
    }
    
    /// Visits a block.
    ///
    /// - Parameter block: The block to be visited.
    private func visitBlock(_ block: ASTBlock) {
        block.body.forEach { $0.visit(self) }
    }
    
    private func createContext(for: ASTStrings) -> Context? {
        // TODO: Implement
        nil
    }
    
    /// Adds the context of the file represented by the given string nodes
    /// to the current context.
    ///
    /// - Parameter file: The strings representing the file name.
    private func addIncluding(file: ASTStrings) {
        if let context = createContext(for: file) {
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
    private func addInheriting(from file: ASTStrings) {
        if let context = createContext(for: file) {
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
    private func visitFunctionCall(function: ASTFunctionCall, id: FunctionDefinition) {
        let arguments = function.arguments
        var tooManyBegin: Int?
        var it = id.parameters.makeIterator()
        var lastArg: ASTExpression?
        
        for argument in arguments {
            lastArg = argument
            argument.visit(self)
            
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
    private func visitFunctionCall(function: ASTFunctionCall, ids: [Definition]) -> TypeProto? {
        for id in ids {
            if let fd = id as? FunctionDefinition,
               fd.parameters.count == function.arguments.count || fd.variadic {
                // TODO: Check types
                visitFunctionCall(function: function, id: fd)
                return fd.returnType
            }
        }
        for id in ids {
            if let fd = id as? FunctionDefinition {
                visitFunctionCall(function: function, id: fd)
                return fd.returnType
            }
        }
        return nil
    }
    
    /// Visits the given unary operation as a super send.
    ///
    /// - Parameter operation: The operation to be visited.
    private func visitSuperFunc(_ operation: ASTUnaryOperation) {
        if let f = cast(type: ASTFunctionCall.self, operation.identifier),
           let n = cast(type: ASTName.self, f.name)?.name {
            let ids = current.getSuperIdentifiers(name: n)
            if ids.isEmpty {
                highlights.append(MessagedHighlight(begin:   operation.begin,
                                                    end:     operation.end,
                                                    type:    .NOT_FOUND,
                                                    message: "Identifier not found"))
            } else {
                currentType = visitFunctionCall(function: f, ids: ids) ?? InterpreterType.any
            }
        }
    }
    
    internal func visit(_ expression: ASTExpression) {
        var highlight = true
        
        switch expression.type {
        case .MISSING:
            highlights.append(MessagedHighlight(begin:   expression.begin,
                                                end:     expression.end,
                                                type:    ASTType.MISSING,
                                                message: (expression as! ASTMissing).message))
            highlight = false
            
        case .WRONG:
            highlights.append(MessagedHighlight(begin:   expression.begin,
                                                end:     expression.end,
                                                type:    ASTType.WRONG,
                                                message: (expression as! ASTWrong).message))
            highlight = false
            
        case .CAST:
            let c = expression as! ASTCast
            c.castExpression.visit(self)
            currentType = cast(type: AbstractType.self, c.castType)! as TypeProto
            
        case .VARIABLE_DEFINITION:
            let varDefinition = expression as! ASTVariableDefinition
            
            let type: AbstractType
            if let t = varDefinition.returnType,
                let unwrapped = cast(type: AbstractType.self, t) {
                type = unwrapped
            } else {
                type = InterpreterType.any
            }
            
            current.addIdentifier(begin: varDefinition.begin,
                                  name:  cast(type: ASTName.self, varDefinition.name)?.name ?? "<unknown>",
                                  type: type,
                                  .VARIABLE_DEFINITION)
            maybeWrongVoid(type)
            currentType = type
            
        case .FUNCTION_DEFINITION:
            let function         = expression as! ASTFunctionDefinition
            let block            = function.body
            let paramExpressions = function.parameters
            
            let retType = cast(type: AbstractType.self, function.returnType)!
            retType.visit(self)
            let params  = visitParams(of: function)
            
            current = current.addFunction(begin:      function.begin,
                                          scopeBegin: block.begin,
                                          name:       cast(type: ASTName.self,      function.name)!,
                                          returnType: cast(type: AbstractType.self, function.returnType)!,
                                          parameters: params,
                                          variadic:   paramExpressions.last?.type == .AST_ELLIPSIS)
            visitBlock(cast(type: ASTBlock.self, block)!)
            current = current.popScope(end: expression.end)!
            currentType = InterpreterType.void
            
        case .BLOCK:
            current = current.pushScope(begin: expression.begin)
            visitBlock(expression as! ASTBlock)
            current = current.popScope(end: expression.end)!
            currentType = InterpreterType.void
            
        case .AST_INCLUDE:
            addIncluding(file: cast(type: ASTStrings.self, (expression as! ASTInclude).included)!)
            
        case .AST_INHERITANCE:
            let inheritance = expression as! ASTInheritance
            
            if let inherited = inheritance.inherited {
                addInheriting(from: cast(type: ASTStrings.self, inherited)!)
            } else {
                highlight = false
                highlights.append(MessagedHighlight(begin:   inheritance.begin,
                                                    end:     inheritance.end,
                                                    type:    .WARNING,
                                                    message: "Inheriting from nothing"))
            }
            
        case .FUNCTION_CALL:
            let fc = expression as! ASTFunctionCall
            
            let name = cast(type: ASTName.self, fc.name)!
            name.visit(self)
            if let n = name.name {
                let ids = current.getIdentifiers(name: n, pos: name.begin)
                if !ids.isEmpty {
                    currentType = visitFunctionCall(function: fc, ids: ids) ?? InterpreterType.any
                }
            }
            
        case .NAME:
            let name = expression as! ASTName
            if let n = name.name {
                let identifiers = current.getIdentifiers(name: n, pos: name.begin)
                if let first = identifiers.first {
                    highlights.append(Highlight(begin: expression.begin,
                                                end:   expression.end,
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
                    currentType = InterpreterType.any
                }
                highlight = false
            }
            
        case .UNARY_OPERATOR:
            let operation = expression as! ASTUnaryOperation
            
            if operation.operatorType == .SCOPE {
                visitSuperFunc(operation)
            } else {
                operation.identifier.visit(self)
            }
            
        case .OPERATION:
            let operation = expression as! ASTOperation
            let rhs       = operation.rhs
            operation.lhs.visit(self)
            
            let lhsType = currentType
            
            if operation.operatorType == .ARROW ||
               operation.operatorType == .DOT {
                // TODO: Load if possible
                _ = cast(type: ASTFunctionCall.self, rhs)
            } else {
                rhs.visit(self)
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
                
            case .RANGE, .ELLIPSIS,
                 .ARROW, .DOT:                currentType = InterpreterType.any
                
            case .ASSIGNMENT,      .OR,
                 .AMPERSAND,       .PIPE,
                 .LEFT_SHIFT,      .RIGHT_SHIFT,
                 .DOUBLE_QUESTION, .QUESTION,
                 .INCREMENT,       .DECREMENT,
                 .COLON,           .PLUS,
                 .MINUS,           .STAR,
                 .SLASH,           .PERCENT,
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
            
            condition.visit(self)
            if !InterpreterType.bool.isAssignable(from: currentType) {
                highlights.append(MessagedHighlight(begin:   condition.begin,
                                                    end:     condition.end,
                                                    type:    .TYPE_MISMATCH,
                                                    message: "Condition should be a boolean expression"))
            }
            i.instruction.visit(self)
            i.elseInstruction?.visit(self)
            
        case .AST_RETURN:
            let ret      = expression as! ASTReturn
            let returned = ret.returned
            
            if let returned {
                returned.visit(self)
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
            // TODO: Unwrap and check for void in parameter types
            break
         
        case .AST_ELLIPSIS:
            let enclosing = current.queryEnclosingFunction()
            if enclosing == nil || !enclosing!.variadic {
                highlights.append(MessagedHighlight(begin:   expression.begin,
                                                    end:     expression.end,
                                                    type:    .ERROR,
                                                    message: "Enclosing function is not variadic"))
                highlight = false
            }
            currentType = InterpreterType.any
            
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
        type != .FUNCTION_CALL
    }
}
