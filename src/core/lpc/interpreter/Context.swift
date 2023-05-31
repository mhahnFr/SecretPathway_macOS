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

/// This class represents an interpretation context.
class Context: Instruction {
    let begin: Int
    let returnType: TypeProto = InterpreterType.void
    /// The optional parent context.
    let parent: Context?
    /// The name of the file from which this context was created.
    let fileName: String?
    
    /// The instruction contained in this context.
    private(set) var instructions: [Int: Instruction] = [:]
    
    var end = 0
    /// The enclosing context, used for classes.
    var enclosing: Context?
    /// The included context objects.
    var included: [Context] = []
    /// The inherited context objects.
    var inherited: [Context] = []
    /// Indicates whether this context explicitly does not inherit from anything.
    var noInheritance = false
    /// The classes declared in this context.
    var classes = [String: Context]()
    /// The global scope in which this context is in.
    var fileGlobal: Context {
        if let parent {
            return parent.fileGlobal
        }
        return self
    }
    
    /// Constructs this context using the optional beginning position
    /// and the optional parent context.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - parent: The parent context.
    ///   - fileName: The name of the file from which this context is created.
    init(begin: Int = 0, parent: Context? = nil, fileName: String? = nil) {
        self.begin    = begin
        self.parent   = parent
        self.fileName = fileName
    }
    
    /// Pushes this scope.
    ///
    /// - Parameter begin: The beginning position of the subscope.
    /// - Returns: The subscope context object.
    func pushScope(begin: Int) -> Context {
        let newContext = Context(begin: begin, parent: self)
        instructions[begin] = newContext
        return newContext
    }
    
    /// Pops this scope if possible.
    ///
    /// - Parameter end: The end position of this scope context.
    /// - Returns: The parent scope context object.
    func popScope(end: Int) -> Context? {
        self.end = end
        
        return parent
    }
    
    /// Adds a named identifier to this context.
    ///
    /// - Parameters:
    ///   - begin: The beginning position of the identifier.
    ///   - name: The name of the identifier.
    ///   - type: The return type of the identifier.
    ///   - kind: The AST type of the identifier.
    ///   - modifiers: The modifiers of the identifier to be added.
    /// - Returns: Returns whether the added identifier does not redeclare another one.
    func addIdentifier(begin:     Int,
                       name:      String,
                       type:      TypeProto,
                       _ kind:    ASTType,
                       modifiers: Modifier) -> Bool {
        let notRedeclaring = instructions.first { ($0.value as? Definition)?.name == name } == nil
        if notRedeclaring {
            instructions[begin] = Definition(begin: begin, returnType: type, name: name, kind: kind, modifiers: modifiers)
        }
        return notRedeclaring
    }
    
    /// Adds a function to this scope. The given parameters are
    /// added to the subcontext of the added function definition.
    ///
    /// - Parameters:
    ///   - begin: The beginning position of the function definition.
    ///   - scopeBegin: The beginning position of the function's scope.
    ///   - name: The name of the function.
    ///   - returnType: The return type of the function.
    ///   - parameters: The parameter definitions and name expressions.
    ///   - variadic: Indicates whether the function has variadic parameters.
    ///   - modifiers: The modifiers of the function to be added.
    /// - Returns: The subscope context object of the function's body and the redeclared name expressions.
    func addFunction(begin:      Int,
                     scopeBegin: Int,
                     name:       ASTName,
                     returnType: TypeProto,
                     parameters: [(ASTName?, Definition)],
                     variadic:   Bool,
                     modifiers:  Modifier) -> (Context, [ASTName?]) {
        var redefinitions = [ASTName?]()
        let previous = instructions.first {
            if let fd = $0.value as? FunctionDefinition {
                if fd.name             == name.name,
                   fd.parameters.count == parameters.count,
                   fd.variadic         == variadic {
                   
                    for i in 0 ..< parameters.count {
                        guard parameters[i].1.returnType.isAssignable(from: fd.parameters[i].returnType) else {
                            return false
                        }
                    }
                    return true
                }
            } else if let def = $0.value as? Definition,
                      def.name == name.name {
                return true
            }
            return false
        }
        var paramDefs = [Definition]()
        parameters.forEach { paramDefs.append($0.1) }
        let function = FunctionDefinition(begin:      begin,
                                          name:       name.name ?? "<< unknown >>",
                                          returnType: returnType,
                                          parameters: paramDefs,
                                          variadic:   variadic,
                                          modifiers:  modifiers)
        if previous == nil {
            instructions[begin] = function
        } else {
            redefinitions.append(name)
        }
        
        let newContext = pushScope(begin: scopeBegin)
        parameters.forEach {
            let name = $0.1.name
            if newContext.instructions.first(where: { ($0.value as? Definition)?.name == name }) == nil {
                newContext.instructions[$0.1.begin] = $0.1
            } else {
                redefinitions.append($0.0)
            }
        }
        return (newContext, redefinitions)
    }
    
    /// Returns all identifiers of the given name inside the inherited
    /// contexts.
    ///
    /// - Parameter name: The name of the searched identifier.
    /// - Parameter includeProtected: Indicates whether to include protected identifiers as well.
    /// - Returns: A list with all found identifiers.
    func getSuperIdentifiers(name: String, includeProtected: Bool) -> [Definition] {
        if let parent {
            return parent.getSuperIdentifiers(name: name, includeProtected: includeProtected)
        }
        
        for context in inherited {
            let identifiers = context.getIdentifiers(name: name, pos: Int.max, includePrivate: false, includeProtected: includeProtected)
            if !identifiers.isEmpty {
                return identifiers
            }
        }
        return []
    }
    
    /// Returns all identifiers of the given name available at the given position.
    ///
    /// - Parameters:
    ///   - name: The name of the requested identifiers.
    ///   - pos: The position.
    ///   - includePrivate: Indicates whether to include private identifiers.
    ///   - includeProtected: Indicates whether to include protected identifiers.
    /// - Returns: A list with all found identifiers.
    func getIdentifiers(name: String, pos: Int, includePrivate: Bool, includeProtected: Bool) -> [Definition] {
        var definitions: [Definition] = []
        for (begin, instruction) in instructions {
            if begin < pos,
               let definition = instruction as? Definition,
               definition.name == name,
               !definition.modifiers.isPrivate   || includePrivate,
               !definition.modifiers.isProtected || includeProtected {
                definitions.append(definition)
            }
        }
        if !definitions.isEmpty {
            return definitions
        }
        
        if let parent {
            return parent.getIdentifiers(name: name, pos: pos, includePrivate: includePrivate, includeProtected: includeProtected)
        }
        
        for incl in included {
            let identifiers = incl.getIdentifiers(name: name, pos: Int.max, includePrivate: false, includeProtected: false)
            if !identifiers.isEmpty {
                return identifiers
            }
        }
        
        return getSuperIdentifiers(name: name, includeProtected: includeProtected)
    }
    
    /// Returns the function definition this context is in.
    ///
    /// - Returns: The enclosing function or `nil` if there is none.
    func queryEnclosingFunction() -> FunctionDefinition? {
        guard let parent else { return nil }
        
        if let previous   = Array(parent.instructions.keys).sorted(by: <).last(where: { $0 < begin }),
           let definition = parent.instructions[previous] as? FunctionDefinition {
            return definition
        } else {
            return parent.queryEnclosingFunction()
        }
    }
    
    /// Returns whether this context inherits directly or indirectly from
    /// the given file.
    ///
    /// - Parameter file: The file name.
    /// - Returns: Whether this context inherits from the given file.
    func inheritsFrom(file: String) -> Bool {
        for inherit in inherited {
            let lhs: String?
            let rhs: String?
            if inherit.fileName?.starts(with: "/") ?? false && !file.starts(with: "/") {
                if let cut = inherit.fileName?.dropFirst() {
                    lhs = String(cut)
                } else {
                    lhs = nil
                }
                rhs = file
            } else if file.starts(with: "/") && !(inherit.fileName?.starts(with: "/") ?? true) {
                lhs = inherit.fileName
                rhs = String(file.dropFirst())
            } else {
                lhs = inherit.fileName
                rhs = file
            }
            if lhs == rhs || inherit.inheritsFrom(file: file) {
                return true
            }
        }
        return false
    }
    
    /// Adds a class with the given context and the given name expression
    /// ot this context.
    ///
    /// - Parameters:
    ///   - context: The interpretation context of the new class.
    ///   - name: The name expression of the new class.
    /// - Returns: Whether a class with the same name already exists.
    func addClass(context: Context, name: ASTName) -> Bool {
        guard let n = name.name else { return false }
        guard classes[n] == nil else { return true  }
        
        classes[n] = context
        
        return false
    }
    
    /// Returns whether the given position is in the global scope.
    ///
    /// - Parameter position: The position to be checked.
    /// - Returns: Whether the position is at global scope.
    func isGlobalScope(at position: Int) -> Bool {
        for (pos, instruction) in instructions {
            if pos < position,
               instruction.end > position {
                return !(instruction is Context)
            }
        }
        return true
    }
    
    /// Creates the super send suggestions.
    ///
    /// - Returns: The computed suggestions.
    func createSuperSuggestions() -> [any Suggestion] {
        var set = Set<AnyHashable>()
        
        inherited.forEach { $0.availableDefinitions(at: .max, with: .literal).forEach { set.insert(AnyHashable($0)) } }
        set.remove(AnyHashable(PlainSuggestion("...")))
        set.remove(AnyHashable(ReturnSuggestion()))
        set.remove(AnyHashable(ValueReturnSuggestion(value: true)))
        set.remove(AnyHashable(ValueReturnSuggestion(value: false)))
        set.remove(AnyHashable(ValueReturnSuggestion()))
        set.remove(AnyHashable(ThisSuggestion()))
        
        var toReturn = [any Suggestion]()
        set.forEach { toReturn.append($0.base as! any Suggestion) }
        return toReturn
    }
    
    /// Returns the available definitions at the given position.
    ///
    /// - Parameters:
    ///   - position: The position.
    ///   - type: The type of the suggestions.
    /// - Returns: The computed suggestions.
    private func availableDefinitions(at position: Int, with type: SuggestionType) -> [any Suggestion] {
        // Note from the author: The following code is by far the worst Swift code that I have written so far.
        var set = Set<AnyHashable>()
        
        for (pos, instruction) in instructions {
            if pos < position {
                if let value = instruction as? Definition {
                    set.insert(AnyHashable(DefinitionSuggestion(definition: value)))
                } else if let value = instruction as? Context,
                          position < value.end {
                    value.availableDefinitions(at: position, with: type).forEach { set.insert(AnyHashable($0)) }
                }
            }
        }
        
        var superSuggestions = createSuperSuggestions()
        for (i, element) in superSuggestions.enumerated() {
            if let suggestion = element as? DefinitionSuggestion,
               set.contains(where: { ($0.base as! any Suggestion).suggestion == suggestion.suggestion }) { // set.contains(AnyHashable(suggestion))
                superSuggestions[i] = DefinitionSuggestion(suggestion, isSuper: true)
            }
        }
        superSuggestions.forEach { set.insert(AnyHashable($0)) }
        
        included.forEach { $0.availableDefinitions(at: .max, with: type).forEach { set.insert(AnyHashable($0)) } }
        
        if let definition = queryEnclosingFunction() {
            set.insert(AnyHashable(ThisSuggestion()))
            if definition.variadic { set.insert(AnyHashable(PlainSuggestion("..."))) }
            if type.isType(.any) {
                if InterpreterType.bool.isAssignable(from: definition.returnType) {
                    set.insert(AnyHashable(ValueReturnSuggestion(value: true)))
                    set.insert(AnyHashable(ValueReturnSuggestion(value: false)))
                } else if InterpreterType.void.isAssignable(from: definition.returnType) {
                    set.insert(AnyHashable(ReturnSuggestion()))
                } else {
                    set.insert(AnyHashable(ValueReturnSuggestion()))
                }
            }
        }
        
        var toReturn = [any Suggestion]()
        set.forEach { toReturn.append($0.base as! any Suggestion) }
        return toReturn
    }
    
    /// Creates the possible suggestions at the given position of the given type.
    ///
    /// - Parameters:
    ///   - position: The position.
    ///   - type: The type of suggestions.
    /// - Returns: The computed suggestions.
    func createSuggestions(at position: Int, with type: SuggestionType) -> [any Suggestion] {
        guard !type.isType(.literal) else { return [] }
        
        var toReturn = [any Suggestion]()
        
        if type.isType(.any, .identifier, .literalIdentifier) {
            toReturn.append(contentsOf: availableDefinitions(at: position, with: type))
        }
        
        if type.isType(.any, .type, .typeModifier) {
            toReturn.append(TypeSuggestion(type: .OBJECT))
            toReturn.append(TypeSuggestion(type: .ANY))
            toReturn.append(TypeSuggestion(type: .INT_KEYWORD))
            toReturn.append(TypeSuggestion(type: .STRING_KEYWORD))
            toReturn.append(TypeSuggestion(type: .CHAR_KEYWORD))
            toReturn.append(TypeSuggestion(type: .SYMBOL_KEYWORD))
            toReturn.append(TypeSuggestion(type: .VOID))
            toReturn.append(TypeSuggestion(type: .BOOL))
            toReturn.append(TypeSuggestion(type: .MIXED))
            toReturn.append(TypeSuggestion(type: .MAPPING))
        }
        
        if type.isType(.any, .literalIdentifier) {
            toReturn.append(ValueSuggestion(value: TokenType.NIL))
            toReturn.append(ValueSuggestion(value: TokenType.TRUE))
            toReturn.append(ValueSuggestion(value: TokenType.FALSE))
        }
        
        if isGlobalScope(at: position) {
            toReturn.append(InheritSuggestion())
            toReturn.append(IncludeSuggestion())
            toReturn.append(ClassSuggestion())
            
            if type.isType(.any, .modifier, .typeModifier) {
                toReturn.append(TypeSuggestion(type: .PRIVATE))
                toReturn.append(TypeSuggestion(type: .PROTECTED))
                toReturn.append(TypeSuggestion(type: .PUBLIC))
                toReturn.append(TypeSuggestion(type: .OVERRIDE))
                toReturn.append(TypeSuggestion(type: .NOSAVE))
                toReturn.append(TypeSuggestion(type: .DEPRECATED))
            }
        } else {
            if type.isType(.any, .identifier, .literalIdentifier) {
                toReturn.append(NewSuggestion())
            }
            if type.isType(.any) {
                toReturn.append(ParenthesizedSuggestion(keyword: .IF))
                toReturn.append(TrySuggestion())
                toReturn.append(ParenthesizedSuggestion(keyword: .FOR))
                toReturn.append(ParenthesizedSuggestion(keyword: .FOREACH))
                toReturn.append(ParenthesizedSuggestion(keyword: .WHILE))
                toReturn.append(DoSuggestion())
                toReturn.append(SwitchSuggestion())
            }
        }
        
        return toReturn
    }
    
    /// Returns the function enclosing the given position.
    ///
    /// - Parameter position: The position.
    /// - Returns: The found function definition or `nil`.
    func queryEnclosingFunction(at position: Int) -> FunctionDefinition? {
        if let previous = Array(instructions.keys).sorted(by: <).last(where: { $0 < position}),
           let function = instructions[previous] as? FunctionDefinition {
            return function
        }
        return nil
    }
    
    /// Digs out the identifiers of the given name available at the given position.
    ///
    /// - Parameters:
    ///   - name: The name of the identifiers.
    ///   - position: The position.
    /// - Returns: The found identifiers.
    func digOutIdentifiers(_ name: String, for position: Int) -> [Definition] {
        if let subEntry   = Array(instructions.keys).sorted(by: <).last(where: { $0 < position}),
           let subContext = instructions[subEntry] as? Context {
            return subContext.digOutIdentifiers(name, for: position)
        }
        return getIdentifiers(name: name, pos: position, includePrivate: true, includeProtected: true)
    }
}
