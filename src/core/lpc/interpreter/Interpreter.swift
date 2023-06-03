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
    
    /// The file loader used for resolving indicated files.
    private let loader: LPCFileManager
    /// The optional file name of the referring file.
    private let referrer: String?
    
    /// The currently used context object.
    private var current = Context()
    /// The return type of the lastly interpreted expression.
    private var currentType: TypeProto = InterpreterType.any
    /// Indicates whether the processed AST is a background AST.
    private var background = false
    
    /// Initializes this instance using the given file loader.
    ///
    /// - Parameter loader: The file loader used for fetching additional files.
    /// - Parameter referrer: The file name of the optional referrer.
    init(loader: LPCFileManager, referrer: String? = nil) {
        self.loader   = loader
        self.referrer = referrer
    }
    
    /// Creates and returns a context object for the given AST.
    ///
    /// - Parameter ast: The AST to be interpreted.
    /// - Parameter name: The name of the file whose AST is to be interpreted.
    /// - Returns: The interpretation context.
    func createContext(for ast: [ASTExpression], file name: String? = nil) async -> Context {
        background = false
        highlights = []
        current    = Context(fileName: name)
        
        for node in ast { await node.visit(self) }
        
        await assertInheritance(for: current)
        
        return current
    }
    
    /// Creates and returns a context object for the given AST.
    ///
    /// Runs in the background mode.
    ///
    /// - Parameters:
    ///   - ast: The AST to be interpreted.
    ///   - name: The name of the file whose AST is to be interpreted.
    /// - Returns: The interpretation context.
    func createBackgroundContext(for ast: [ASTExpression], file name: String) async -> Context {
        background = true
        current = Context(fileName: name)
        
        for node in ast { await node.visit(self) }
        
        await assertInheritance(for: current)
        
        return current
    }
    
    /// Asserts the validity of the inheritition of the given context.
    ///
    /// - Parameter context: The context to be validated.
    private func assertInheritance(for context: Context) async {
        guard context.inherited.isEmpty,
              !context.noInheritance
        else { return }
        
        guard let defaultInheritance = await loader.getDefaultInheritance(),
              let inheritance = await createContext(for: ASTStrings(strings: [ASTString(token: Token(begin:   0,
                                                                                                     type:    .STRING,
                                                                                                     payload: defaultInheritance,
                                                                                                     end:     0))]))
        else { return }
        
        context.inherited.append(inheritance)
    }
    
    /// Adds the highlight resulting of the given closure if this
    /// interpreter is not in the background mode.
    ///
    /// - Parameter highlight: The highlight to be added.
    private func addHighlight(_ highlight: @autoclosure () -> Highlight) {
        if !background {
            highlights.append(highlight())
        }
    }
    
    /// Returns whether the given type is assignable from the given other type.
    ///
    /// - Parameters:
    ///   - type: The left-hand-side type.
    ///   - other: The right-hand-side type.
    /// - Returns: Whether the type is assignable from the other one.
    private func isAssignable(_ type: TypeProto, from other: TypeProto) async -> Bool {
        if type  === InterpreterType.unknown ||
           other === InterpreterType.unknown {
            return true
        }
        return await type.isAssignable(from: other, loader: background ? nil : loader)
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
            addHighlight(MessagedHighlight(begin:   type.begin,
                                           end:     type.end,
                                           type:    .TYPE_MISMATCH,
                                           message: "'void' not allowed here"))
        }
    }
    
    /// Visits the parameters declarations of the given function declaration.
    ///
    /// - Parameter function: The declared function whose parameters to visit.
    /// - Returns: The definitions created from the declared parameters.
    private func visitParams(of function: ASTFunctionDefinition) async -> [(ASTName?, Definition)] {
        var parameters = [(ASTName?, Definition)]()
        
        for parameter in function.parameters {
            if parameter.type == .MISSING {
                addHighlight(MessagedHighlight(begin:   parameter.begin,
                                               end:     parameter.end,
                                               type:    .MISSING,
                                               message: (parameter as! ASTMissing).message))
            } else if parameter.type != .AST_ELLIPSIS,
                      let param = await cast(type: ASTParameter.self, parameter),
                      let type  = await cast(type: AbstractType.self, param.declaredType) {
                await type.visit(self)
                maybeWrongVoid(type)
                
                let name = await cast(type: ASTName.self, param.name)
                let definition = Definition(begin:      param.begin,
                                            returnType: type,
                                            name:       name?.name ?? "<< unknown >>",
                                            kind:       .PARAMETER,
                                            modifiers:  Modifier())
                definition.end = param.end
                parameters.append((name, definition))
            }
        }
        
        return parameters
    }
    
    /// Creates and returns an interpretation context for the file
    /// indicated by the given strings expression.
    ///
    /// - Parameter file: The strings expression evaluating to the file name.
    /// - Returns: The interpretation context or `nil` if the file could not be interpreted.
    private func createContext(for file: ASTStrings) async -> Context? {
        let fileName = resolve(file.value)
        
        if let referrer {
            var tmpReferrer = referrer
            var tmpFileName = fileName[..<(fileName.firstIndex(of: ":") ?? fileName.endIndex)]
            if tmpReferrer.hasPrefix("/") && !tmpFileName.hasPrefix("/") {
                tmpFileName.insert("/", at: tmpFileName.startIndex)
            } else if tmpFileName.hasPrefix("/") && !tmpReferrer.hasPrefix("/") {
                tmpReferrer.insert("/", at: tmpReferrer.startIndex)
            }
            if tmpReferrer.hasSuffix(".lpc") && !tmpFileName.hasSuffix(".lpc") {
                tmpFileName.append(contentsOf: ".lpc")
            } else if tmpFileName.hasSuffix(".lpc") && !tmpReferrer.hasSuffix(".lpc") {
                tmpReferrer.append(contentsOf: ".lpc")
            }
            
            if tmpReferrer == tmpFileName {
                addHighlight(MessagedHighlight(begin:   file.begin,
                                               end:     file.end,
                                               type:    .ERROR,
                                               message: "Inheriting from itself"))
                return nil
            }
        }
        return await loader.loadAndParse(file: fileName, referrer: current.fileGlobal.fileName ?? referrer ?? "")
    }
    
    /// Resolves the given file name using the file name of the current context.
    ///
    /// - Parameter file: The file name to be resolved.
    /// - Returns: The resolved file name.
    private func resolve(_ file: String) -> String {
        if file.first == "/" { return file }
        
        return VFile(from: file, relation: VFile(from: current.fileGlobal.fileName ?? "")?.folder ?? VPath("", absolute: true))?.fullName ?? file
    }
    
    /// Creates and returns an interpretation context for the file
    /// indicated by the given strings expression if this intepreter
    /// instance is not in the background mode.
    ///
    /// - Parameter file: The strings expression evaluating to the file name.
    /// - Returns: The interpretation context of `nil`.
    private func maybeCreateContext(for file: ASTStrings) async -> Context? {
        background ? nil : await createContext(for: file)
    }
    
    /// Returns whether the file indicated by the given strings expression exists.
    ///
    /// - Parameter file: The strings expression evaluating to the file name.
    /// - Returns: Whether the file exists.
    private func fileExists(file: ASTStrings) async -> Bool {
        background ? true : await loader.exists(file: file.value)
    }
    
    /// Adds the context of the file represented by the given string nodes
    /// to the current context.
    ///
    /// - Parameter file: The strings representing the file name.
    private func addIncluding(file: ASTStrings) async {
        if let context = await createContext(for: file) {
            current.included.append(context)
        } else {
            addHighlight(MessagedHighlight(begin:   file.begin,
                                           end:     file.end,
                                           type:    .UNRESOLVED,
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
            addHighlight(MessagedHighlight(begin:   file.begin,
                                           end:     file.end,
                                           type:    .UNRESOLVED,
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
                if await !isAssignable(next.returnType, from: currentType) {
                    addHighlight(MessagedHighlight(begin:   argument.begin,
                                                   end:     argument.end,
                                                   type:    .TYPE_MISMATCH,
                                                   message: "\(next.returnType.string) is not assignable from \(currentType.string)"))
                }
            } else {
                if !id.variadic && tooManyBegin == nil {
                    tooManyBegin = argument.begin
                }
            }
        }
        
        if let tooManyBegin {
            addHighlight(MessagedHighlight(begin:   tooManyBegin,
                                           end:     arguments.last!.end,
                                           type:    .ERROR,
                                           message: "Expected \(id.parameters.count) arguments, got \(arguments.count)"))
        }
        if it.next() != nil {
            addHighlight(MessagedHighlight(begin:   lastArg?.end ?? function.begin,
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
            await assertInheritance(for: current.fileGlobal)
            let ids = current.getSuperIdentifiers(name: n, includeProtected: true)
            if ids.isEmpty {
                addHighlight(MessagedHighlight(begin:   operation.begin,
                                               end:     operation.end,
                                               type:    .UNRESOLVED,
                                               message: "Identifier not found"))
            } else {
                currentType = await visitFunctionCall(function: f, ids: ids) ?? InterpreterType.unknown
            }
        }
    }
    
    /// Visists a function reference expression.
    ///
    /// - Parameter operation: The function reference operation.
    private func visitFunctionReference(_ operation: ASTUnaryOperation) async {
        guard let name       = await cast(type: ASTName.self, operation.identifier),
              let nameString = name.name else { return }
        
        await assertInheritance(for: current.fileGlobal)
        let ids = current.getIdentifiers(name: nameString, pos: operation.begin, includePrivate: true, includeProtected: true)
        if !ids.isEmpty {
            for id in ids {
                if let i = id as? FunctionDefinition {
                    var parameterTypes = [TypeProto?]()
                    i.parameters.forEach { parameterTypes.append($0.returnType) }
                    currentType = InterpreterFuncRefType(returnType:     i.returnType,
                                                         parameterTypes: parameterTypes,
                                                         variadic:       i.variadic)
                    return
                }
            }
        }
        addHighlight(MessagedHighlight(begin:   name.begin,
                                       end:     name.end,
                                       type:    .NOT_FOUND,
                                       message: "Identifier not found"))
    }
    
    /// Visits a name expression.
    ///
    /// - Parameters:
    ///   - context: The context in which to search for the identifier.
    ///   - name: The name expression to be resolved.
    ///   - asFunction: Indicates whether to treat the given name expression as a function name.
    private func visitName(context: Context, name: ASTName, asFunction: Bool) {
        if let n = name.name {
            let thisContext = context === current
            let identifiers = context.getIdentifiers(name: n, pos: thisContext ? name.begin : Int.max, includePrivate: thisContext, includeProtected: thisContext)
            if let first = identifiers.first {
                if first is FunctionDefinition == asFunction {
                    addHighlight(Highlight(begin: name.begin,
                                           end:   name.end,
                                           type:  first.kind))
                    currentType = first.returnType
                } else {
                    addHighlight(MessagedHighlight(begin:   name.begin,
                                                   end:     name.end,
                                                   type:    .TYPE_MISMATCH,
                                                   message: asFunction ? "Not a function"
                                                                       : "Not a variable"))
                }
                if first.modifiers.isDeprecated {
                    addHighlight(MessagedHighlight(begin:   name.begin,
                                                   end:     name.end,
                                                   type:    .INTERPRETER_DEPRECATED,
                                                   message: "Identifier is marked deprecated"))
                }
            } else {
                if n.starts(with: "$") {
                    addHighlight(MessagedHighlight(begin:   name.begin,
                                                   end:     name.end,
                                                   type:    .NOT_FOUND_BUILTIN,
                                                   message: "Built-in not found"))
                } else {
                    addHighlight(MessagedHighlight(begin:   name.begin,
                                                   end:     name.end,
                                                   type:    .NOT_FOUND,
                                                   message: "Identifier not found"))
                }
                currentType = InterpreterType.unknown
            }
        }
    }
    
    /// Visits a `new` expression.
    ///
    /// - Parameter expression: The expression to be visited.
    /// - Returns: The return type of the expression.
    private func visitNew(expression: ASTNew) async -> TypeProto {
        guard let strings = await cast(type: ASTStrings.self, expression.instancingExpression),
              let context = await maybeCreateContext(for: strings) else {
            addHighlight(MessagedHighlight(begin:   expression.instancingExpression.begin,
                                           end:     expression.instancingExpression.end,
                                           type:    .UNRESOLVED,
                                           message: "Could not resolve file"))
            for argument in expression.arguments {
                await argument.visit(self)
            }
            return InterpreterType.object
        }
        let ids = context.getIdentifiers(name: "create", pos: Int.max, includePrivate: false, includeProtected: false)
        if await visitFunctionCall(function: expression, ids: ids) == nil {
            addHighlight(MessagedHighlight(begin:   expression.instancingExpression.begin,
                                           end:     expression.instancingExpression.end,
                                           type:    .WARNING,
                                           message: "No constructor found"))
            for argument in expression.arguments {
                await argument.visit(self)
            }
        }
        return InterpreterType(type: .OBJECT, file: strings.value)
    }
    
    /// Visits the given modifiers.
    ///
    /// - Parameter modifiers: The modifier expressions to be visited.
    /// - Returns: The modfiers abstraction.
    private func visitModifiers(_ modifiers: [ASTExpression]) async -> Modifier {
        var mods = Modifier()
        var accessModifiers = [ASTModifier]()
        
        for modifier in modifiers {
            if let actual = await cast(type: ASTModifier.self, modifier) {
                let was: Bool
                switch actual.modifier {
                case .NOSAVE:
                    was = mods.isNosave
                    mods.isNosave = true
                    
                case .DEPRECATED:
                    was = mods.isDeprecated
                    mods.isDeprecated = true
                    
                case .OVERRIDE:
                    was = mods.isOverride
                    mods.isOverride = true
                    
                case .PUBLIC:
                    was = mods.isPublic
                    mods.isPublic = true
                    accessModifiers.append(actual)
                    
                case .PRIVATE:
                    was = mods.isPrivate
                    mods.isPrivate = true
                    accessModifiers.append(actual)

                case .PROTECTED:
                    was = mods.isProtected
                    mods.isProtected = true
                    accessModifiers.append(actual)

                default: was = false
                }
                if was {
                    addHighlight(MessagedHighlight(begin:   actual.begin,
                                                   end:     actual.end,
                                                   type:    .WARNING,
                                                   message: "Already declared \(actual.modifier?.rawValue.lowercased() ?? "<unknown>")"))
                }
            }
        }
        if accessModifiers.count > 1 {
            accessModifiers.forEach {
                addHighlight(MessagedHighlight(begin:   $0.begin,
                                               end:     $0.end,
                                               type:    .WARNING,
                                               message: "Mixing access modifiers"))
            }
        }
        return mods
    }
    
    /// Creates a context that is associated with the given type.
    ///
    /// - Parameter type: The type to be resolved.
    /// - Returns: The context derived from the given type or `nil` if impossible.
    private func maybeCreateContext(for type: TypeProto) async -> Context? {
        if let t = type as? ThisType {
            if let name = (t.typeFile as? ASTStrings)?.value {
                return current.fileGlobal.digOutClass(name: name)
            }
            return current.fileGlobal
        } else if let t = type as? BasicType,
                  let tFile = t.typeFile as? ASTStrings {
            return await maybeCreateContext(for: tFile)
        }
        return nil
    }
    
    /// Visits the given scope chain relative to the given type.
    ///
    /// - Parameters:
    ///   - lhsType: The type on the left-hand-side.
    ///   - rhs: The scope chain on the right-hand-side.
    /// - Returns: The appopriate type representation.
    private func visitScopeChain(lhsType: TypeProto, rhs: ASTScopeChain) async -> TypeProto {
        guard let context = await maybeCreateContext(for: lhsType) else { return InterpreterType.unknown }
        
        var nameString = context.fileName ?? "<unknown>"
        var error      = false
        var tmp        = context
        for name in rhs.names {
            if let name = await cast(type: ASTName.self, name),
               let n    = name.name {
                nameString.append("::\(n)")
                if !error {
                    if let classContext = tmp.classes[n] {
                        tmp = classContext
                    } else {
                        error = true
                        addHighlight(MessagedHighlight(begin:   name.begin,
                                                       end:     name.end,
                                                       type:    .NOT_FOUND,
                                                       message: "Class \"\(n)\" not found"))
                    }
                }
            }
        }
        
        return ThisType(file: nameString)
    }
    
    internal func visit(_ expression: ASTExpression) async {
        var highlight = true
        
        switch expression.type {
        case .MISSING, .WRONG:
            addHighlight(MessagedHighlight(begin:   expression.begin,
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
            
            let idName = await cast(type: ASTName.self, varDefinition.name)?.name ?? "<unknown>"
            let modifiers = await visitModifiers(varDefinition.modifiers)
            if !current.addIdentifier(begin:     varDefinition.begin,
                                      name:      idName,
                                      type:      type,
                                      .VARIABLE_DEFINITION,
                                      modifiers: modifiers) {
                addHighlight(MessagedHighlight(begin:   varDefinition.name.begin,
                                               end:     varDefinition.name.end,
                                               type:    .ERROR,
                                               message: "Redeclaring identifier \"\(idName)\""))
            }
            await assertInheritance(for: current.fileGlobal)
            if modifiers.isOverride,
               current.getSuperIdentifiers(name: idName, includeProtected: true).isEmpty {
                addHighlight(MessagedHighlight(begin:   varDefinition.name.begin,
                                               end:     varDefinition.name.end,
                                               type:    .WARNING,
                                               message: "Identifier is marked override but overrides nothing"))
            }
            maybeWrongVoid(type)
            currentType = type
            
        case .FUNCTION_DEFINITION:
            let function         = expression as! ASTFunctionDefinition
            let block            = function.body
            let paramExpressions = function.parameters
            
            let retType = await cast(type: AbstractType.self, function.returnType)!
            await retType.visit(self)
            let params  = await visitParams(of: function)

            let name = await cast(type: ASTName.self, function.name)!
            let modifiers = await visitModifiers(function.modifiers)
            let (scope, redefs) = await current.addFunction(begin:      function.begin,
                                                            scopeBegin: block.begin,
                                                            name:       name,
                                                            returnType: cast(type: AbstractType.self, function.returnType)!,
                                                            parameters: params,
                                                            variadic:   paramExpressions.last?.type == .AST_ELLIPSIS,
                                                            modifiers:  modifiers)
            await assertInheritance(for: current.fileGlobal)
            if modifiers.isOverride,
               let n = name.name,
               current.getSuperIdentifiers(name: n, includeProtected: true).isEmpty {
                addHighlight(MessagedHighlight(begin:   name.begin,
                                               end:     name.end,
                                               type:    .WARNING,
                                               message: "Identifier is marked override but overrides nothing"))
            }
            current = scope
            redefs.forEach {
                guard let name = $0 else { return }
                
                addHighlight(MessagedHighlight(begin:   name.begin,
                                               end:     name.end,
                                               type:    .ERROR,
                                               message: "Redefinition of \"\(name.name ?? "<< unknown >>")\""))
            }
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
            if let file = await cast(type: ASTStrings.self, (expression as! ASTInclude).included) {
                await addIncluding(file: file)
            }
            
        case .AST_INHERITANCE:
            let inheritance = expression as! ASTInheritance
            
            if let inherited = inheritance.inherited {
                await addInheriting(from: cast(type: ASTStrings.self, inherited)!)
            } else {
                current.noInheritance = true
                highlight             = false
                addHighlight(MessagedHighlight(begin:   inheritance.begin,
                                               end:     inheritance.end,
                                               type:    .WARNING,
                                               message: "Inheriting from nothing"))
            }
            
        case .FUNCTION_CALL:
            let fc = expression as! ASTFunctionCall
            
            let name = await cast(type: ASTName.self, fc.name)!
            await assertInheritance(for: current.fileGlobal)
            visitName(context: current, name: name, asFunction: true)
            if let n = name.name {
                let ids = current.getIdentifiers(name: n, pos: name.begin, includePrivate: true, includeProtected: true)
                if !ids.isEmpty {
                    currentType = await visitFunctionCall(function: fc, ids: ids) ?? InterpreterType.unknown
                    break
                }
            }
            for argument in fc.arguments { await argument.visit(self) }
            currentType = InterpreterType.unknown
            
        case .NAME:
            await assertInheritance(for: current.fileGlobal)
            visitName(context: current, name: expression as! ASTName, asFunction: false)
            highlight = false
            
        case .UNARY_OPERATOR:
            let operation = expression as! ASTUnaryOperation
            
            switch operation.operatorType {
            case .SCOPE:     await visitSuperFunc(operation)
            case .AMPERSAND: await visitFunctionReference(operation)
            case .NOT:       currentType = InterpreterType.bool
            case .STAR:
                if let string = operation.identifier as? ASTStrings,
                   await !fileExists(file: string) {
                    addHighlight(MessagedHighlight(begin:   string.begin,
                                                   end:     string.end,
                                                   type:    .UNRESOLVED,
                                                   message: "Could not resolve file"))
                }
                
            default: await operation.identifier.visit(self)
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
                    if let context = await maybeCreateContext(for: lhsType) {
                        await assertInheritance(for: context)
                        visitName(context: context, name: name, asFunction: true)
                        let isThis = lhsType is ThisType
                        currentType = await visitFunctionCall(function: funcCall,
                                                              ids:      context.getIdentifiers(name:             nameStr,
                                                                                               pos:              Int.max,
                                                                                               includePrivate:   isThis,
                                                                                               includeProtected: isThis))
                                      ?? InterpreterType.unknown
                    } else if let leftString = operation.lhs as? ASTStrings,
                              let context    = await maybeCreateContext(for: leftString) {
                        await assertInheritance(for: context)
                        visitName(context: context, name: name, asFunction: true)
                        currentType = await visitFunctionCall(function: funcCall,
                                                              ids:      context.getIdentifiers(name:             nameStr,
                                                                                               pos:              Int.max,
                                                                                               includePrivate:   false,
                                                                                               includeProtected: false))
                                      ?? InterpreterType.unknown
                    } else {
                        for argument in funcCall.arguments { await argument.visit(self) }
                        currentType = InterpreterType.unknown
                    }
                } else {
                    currentType = InterpreterType.unknown
                }
            } else if operation.operatorType == .SCOPE,
                      let chain = await cast(type: ASTScopeChain.self, operation.rhs) {
                currentType = await visitScopeChain(lhsType: lhsType, rhs: chain)
            } else {
                await rhs.visit(self)
            }
            if operation.operatorType == .ASSIGNMENT,
               await !isAssignable(lhsType, from: currentType) {
                addHighlight(MessagedHighlight(begin:   rhs.begin,
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
                 .SCOPE,
                 .ASSIGNMENT_PLUS,
                 .ASSIGNMENT_MINUS,
                 .ASSIGNMENT_STAR,
                 .ASSIGNMENT_SLASH,
                 .ASSIGNMENT_PERCENT:         break
                
            default:                          currentType = InterpreterType.unknown
            }
            
        case .AST_IF:
            let i         = expression as! ASTIf
            let condition = i.condition
            
            await condition.visit(self)
            if await !isAssignable(InterpreterType.bool, from: currentType) {
                addHighlight(MessagedHighlight(begin:   condition.begin,
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
               await !isAssignable(enclosing.returnType, from: currentType) {
                addHighlight(MessagedHighlight(begin:   ret.begin,
                                               end:     ret.end,
                                               type:   .TYPE_MISMATCH,
                                               message: "\(enclosing.returnType.string) is not assignable from \(currentType.string)"))
            }
            
        case .FUNCTION_REFERENCE:
            let funcref = expression as! FunctionReferenceType
            
            await cast(type: AbstractType.self, funcref.returnTypeExpression)?.visit(self)
            for parameter in funcref.parameterTypeExpressions {
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
                addHighlight(MessagedHighlight(begin:   typeFile.begin,
                                               end:     typeFile.end,
                                               type:    .UNRESOLVED,
                                               message: "Could not resolve file"))
            }
            
        case .AST_ELLIPSIS:
            let enclosing = current.queryEnclosingFunction()
            if enclosing == nil || !enclosing!.variadic {
                addHighlight(MessagedHighlight(begin:   expression.begin,
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
                    if await !isAssignable(s, from: currentType) {
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

        case .AST_FOR:
            let loop = expression as! ASTFor
            current  = current.pushScope(begin: loop.begin)
            await loop.initExpression.visit(self)
            await loop.condition.visit(self)
            await loop.afterExpression.visit(self)
            await loop.body.visit(self)
            current  = current.popScope(end: loop.end)!
            
        case .AST_FOREACH:
            let loop = expression as! ASTForEach
            current  = current.pushScope(begin: loop.begin)
            await loop.variable.visit(self)
            let varType = currentType
            await loop.rangeExpression.visit(self)
            let type: TypeProto?
            if let t = currentType as? ArrayTypeProto {
                type = t.underlying
            } else {
                type = currentType
            }
            if await !isAssignable(varType, from: type ?? InterpreterType.unknown),
               !(varType.isAssignable(from: InterpreterType.char) && type?.isAssignable(from: InterpreterType.string) ?? true) {
                addHighlight(MessagedHighlight(begin:   loop.variable.begin,
                                               end:     loop.variable.end,
                                               type:    .TYPE_MISMATCH,
                                               message: "\(varType.string) is not assignable from \(type?.string ?? "<< unknown >>")"))
            }
            await loop.body.visit(self)
            current  = current.popScope(end: loop.end)!
            
        case .TRY_CATCH:
            let tryCatch = expression as! ASTTryCatch
            await tryCatch.tryExpression.visit(self)
            let variable = tryCatch.exceptionVariable
            if let variable {
                current = current.pushScope(begin: variable.begin)
                if let v       = await cast(type: ASTVariableDefinition.self, variable),
                   let retType = v.returnType,
                   let type    = await cast(type: AbstractType.self, retType),
                   let name    = await cast(type: ASTName.self, v.name)?.name {
                    _ = current.addIdentifier(begin:     variable.begin,
                                              name:      name,
                                              type:      type,
                                              .VARIABLE_DEFINITION,
                                              modifiers: Modifier())
                }
            }
            await tryCatch.catchExression.visit(self)
            if variable != nil {
                current = current.popScope(end: tryCatch.catchExression.end)!
            }
            
        case .AST_CLASS:
            let c = expression as! ASTClass
            let enclosing = current
            let name = await cast(type: ASTName.self, c.name)!
            current = Context(fileName: "\(enclosing.fileGlobal.fileName ?? referrer ?? "")::\(name.name ?? "<unknown>")")
            if let inheritance = c.inheritance {
                if let inherit = await cast(type: ASTInheritance.self, inheritance),
                   let expr    = inherit.inherited,
                   let file    = await cast(type: ASTStrings.self, expr),
                   let context = await createContext(for: file) {
                    current.inherited.append(context)
                } else {
                    addHighlight(MessagedHighlight(begin:   inheritance.begin,
                                                   end:     inheritance.end,
                                                   type:    .UNRESOLVED,
                                                   message: "Could not resolve inheritance"))
                }
            }
            for statement in c.statements {
                await statement.visit(self)
            }
            current.enclosing = enclosing
            if enclosing.addClass(context: current,
                                   name:    name) {
                addHighlight(MessagedHighlight(begin:   c.name.begin,
                                               end:     c.name.end,
                                               type:    .ERROR,
                                               message: "Redeclaring class \"\(name.name ?? "<< unknown >>")\""))
            }
            current = enclosing
            
        case .AST_STRING,
             .STRINGS:       currentType = InterpreterType.string
        case .AST_INTEGER:   currentType = InterpreterType.int
        case .AST_FLOAT:     currentType = InterpreterType.float
        case .AST_NIL:       currentType = InterpreterOrType.nilType
        case .AST_SYMBOL:    currentType = InterpreterType.symbol
        case .AST_BOOL:      currentType = InterpreterType.bool
        case .AST_CHARACTER: currentType = InterpreterType.char
        case .AST_THIS:      currentType = ThisType(file: current.fileGlobal.fileName)
            
        default: currentType = InterpreterType.void
        }
        if highlight {
            addHighlight(ASTHighlight(node: expression))
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
        type != .AST_NEW             &&
        type != .AST_FOR             &&
        type != .AST_FOREACH         &&
        type != .TRY_CATCH           &&
        type != .AST_CLASS
    }
}
