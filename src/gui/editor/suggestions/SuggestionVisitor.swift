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

/// This structure implements a suggestion AST visitor.
struct SuggestionVisitor {
    /// The suggestion type to be used for the lastly visited position.
    private(set) var suggestionType = SuggestionType.any
    /// The expected return type of the lastly visited position.
    private(set) var expectedType: TypeProto?
    
    /// The last visited position.
    private var position = -1
    /// The last visited expression.
    private var lastVisited: ASTExpression?
    
    /// Visits the given AST node at the given position, using the given context.
    ///
    /// - Parameters:
    ///   - node: The node to be visitied.
    ///   - position: The position to be visitied.
    ///   - context: The context used to fetch the context information as needed.
    mutating func visit(node: ASTExpression, position: Int, context: Context) {
        guard self.position    !=  position,
              self.lastVisited !== node
        else { return }
        
        self.position    = position
        self.lastVisited = node
        expectedType     = nil
        suggestionType   = visitImpl(node: node, position: position, context: context)
    }
    
    /// Actually visits the given AST node at the given position using the given context.
    ///
    /// - Parameters:
    ///   - node: The node to be visitied.
    ///   - position: The position to be visited.
    ///   - context: The context used.
    /// - Returns: The interpreted suggestion type.
    mutating func visitImpl(node: ASTExpression, position: Int, context: Context) -> SuggestionType {
        switch node.type {
        case .FUNCTION_DEFINITION:
            let fun = node as! ASTFunctionDefinition
            if let last = fun.modifiers.last,
               position <= last.end {
                return .typeModifier
            } else if position <= fun.returnType.end {
                return .typeModifier
            } else if position <= fun.name.end {
                return .literal
            } else if let last = fun.parameters.last,
                      position <= last.end {
                for parameter in fun.parameters {
                    if position >= parameter.begin,
                       position <= parameter.end {
                        return visitImpl(node: parameter, position: position, context: context)
                    }
                }
            } else {
                return visitImpl(node: fun.body, position: position, context: context)
            }
            
        case .VARIABLE_DEFINITION:
            let variable = node as! ASTVariableDefinition
            
            // TODO: isOnSameLine
            if let begin = variable.modifiers.first, position >= begin.begin,
               let end   = variable.modifiers.last,  position <= end.end {
                return .typeModifier
            } else if let returnType = variable.returnType,
                      position >= returnType.begin,
                      position <= returnType.end {
                return .typeModifier
            } else if position >= variable.name.begin,
                      position <= variable.name.end {
                return .literal
            }
            
        case .AST_INHERITANCE, .AST_INCLUDE: return .literal
            
        case .PARAMETER: return position <= (node as! ASTParameter).declaredType.end ? .type : .literal
            
        // TODO: .UNARY_OPERATION?
        case .AST_RETURN:
            let ret = node as! ASTReturn

            if let fun = context.queryEnclosingFunction(at: position) {
                expectedType = fun.returnType
            }
            if let returned = ret.returned,
               position >= returned.begin,
               position <= returned.end {
                return returned.hasSubNodes ? visitImpl(node: returned, position: position, context: context)
                                            : .literalIdentifier
            }
            
        case .CAST:
            let c = node as! ASTCast

            if position <= c.castType.end {
                return .type
            }
            expectedType = cast(TypeProto.self, c.castType)
            return .literalIdentifier
            
        case .MISSING, .WRONG:
            let hole = node as! ASTHole

            if hole.expected == .NAME {
                return .literal
            } else if hole.expected == .TYPE {
                return .type
            } else if hole.expected == .IDENTIFIER {
                return .identifier
            }
            
        case .FUNCTION_CALL:
            let call = node as! ASTFunctionCall
            
            if position <= call.name.end { return .identifier }
            
            let funs = context.getIdentifiers(name:             cast(ASTName.self, call.name)?.name ?? "<unknown>",
                                              pos:              position,
                                              includePrivate:   true,
                                              includeProtected: true)
            let args: [Definition]?
            let funcDef: FunctionDefinition?
            if let def = funs.first(where: {
                guard let f = $0 as? FunctionDefinition else { return false }
                
                return f.parameters.count == call.arguments.count || f.variadic
            }) as? FunctionDefinition {
                args    = def.parameters
                funcDef = def
            } else {
                args    = nil
                funcDef = nil
            }
            
            for (i, param) in call.arguments.enumerated() {
                if position >= param.begin,
                   position <= param.end {
                    if param.hasSubNodes { return visitImpl(node: param, position: position, context: context) }
                    if let args,
                       i < args.count {
                        expectedType = args[i].returnType
                    } else if let funcDef,
                              funcDef.variadic {
                        expectedType = InterpreterType.unknown // or any?
                    }
                    return .identifier
                }
            }
            if expectedType == nil,
               let args, !args.isEmpty {
                expectedType = args[0].returnType
            }
            return .literalIdentifier
            
        case .OPERATION:
            let op = node as! ASTOperation
            
            switch op.operatorType {
            case .ASSIGNMENT:
                switch op.lhs.type {
                case .VARIABLE_DEFINITION:
                    if let typeEx = (op.lhs as! ASTVariableDefinition).returnType {
                        expectedType = cast(TypeProto.self, typeEx)
                    }
                    
                case .NAME:
                    let defs = context.digOutIdentifiers((op.lhs as! ASTName).name ?? "<unknown>", for: position)
                    if !defs.isEmpty {
                        expectedType = defs[0].returnType
                    }
                    
                default: break
                }
                
            default: break
            }
            if position <= op.lhs.end {
                return visitImpl(node: op.lhs, position: position, context: context)
            } else {
                return visitImpl(node: op.rhs, position: position, context: context)
            }
            
        case .AST_CLASS:
            let c = node as! ASTClass
            
            if position < c.name.begin {
                return .typeModifier
            } else if position >= c.name.begin,
                      position <= c.name.end {
                return .literal
            } else if let inheritance = c.inheritance,
                      position >= inheritance.begin,
                      position <= inheritance.end {
                return .literal
            }
            for node in c.statements {
                if position >= node.begin,
                   position <= node.end {
                    guard let classContext = context.classes[cast(ASTName.self, c.name)?.name ?? "<unknown>"] else { return .any }
                    return visitImpl(node: node, position: position, context: classContext)
                }
            }
            
        default:
            for subNode in node.subNodes {
                if position >= subNode.begin,
                   position <= subNode.end {
                    return visitImpl(node: subNode, position: position, context: context)
                }
            }
        }
        return .any
    }
    
    /// Casts the given AST node to the given type.
    ///
    /// If the given AST node is a ASTCombination, it is unwrapped.
    ///
    /// - Parameters:
    ///   - type: The type to cast the node to.
    ///   - expression: The expression to be casted.
    /// - Returns: The casted node or `nil` if not possible.
    private func cast<T>(_ type: T.Type, _ expression: ASTExpression) -> T? {
        if let node = expression as? T {
            return node
        } else if let combination = expression as? ASTCombination {
            for e in combination.expressions {
                if let node = e as? T {
                    return node
                }
            }
        }
        return nil
    }
}
