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
    var enclosing: Context?
    /// The included context objects.
    var included: [Context] = []
    /// The inherited context objects.
    var inherited: [Context] = []
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
    /// - Returns: Returns whether the added identifier does not redeclare another one.
    func addIdentifier(begin: Int, name: String, type: TypeProto, _ kind: ASTType) -> Bool {
        let notRedeclaring = instructions.first { ($0.value as? Definition)?.name == name } == nil
        if notRedeclaring {
            instructions[begin] = Definition(begin: begin, returnType: type, name: name, kind: kind)
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
    /// - Returns: The subscope context object of the function's body and the redeclared name expressions.
    func addFunction(begin:      Int,
                     scopeBegin: Int,
                     name:       ASTName,
                     returnType: TypeProto,
                     parameters: [(ASTName?, Definition)],
                     variadic: Bool) -> (Context, [ASTName?]) {
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
                                          variadic:   variadic)
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
    /// - Returns: A list with all found identifiers.
    func getSuperIdentifiers(name: String) -> [Definition] {
        if let parent {
            return parent.getSuperIdentifiers(name: name)
        }
        
        for context in inherited {
            let identifiers = context.getIdentifiers(name: name, pos: Int.max)
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
    /// - Returns: A list with all found identifiers.
    func getIdentifiers(name: String, pos: Int) -> [Definition] {
        var definitions: [Definition] = []
        for (begin, instruction) in instructions {
            if begin < pos,
               let definition = instruction as? Definition,
               definition.name == name {
                definitions.append(definition)
            }
        }
        if !definitions.isEmpty {
            return definitions
        }
        
        if let parent {
            return parent.getIdentifiers(name: name, pos: pos)
        }
        
        for incl in included {
            let identifiers = incl.getIdentifiers(name: name, pos: Int.max)
            if !identifiers.isEmpty {
                return identifiers
            }
        }
        
        return getSuperIdentifiers(name: name)
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
    
    func addClass(context: Context, name: ASTName) -> Bool {
        guard let n = name.name else { return false }
        guard classes[n] == nil else { return true  }
        
        classes[n] = context
        
        return false
    }
}
