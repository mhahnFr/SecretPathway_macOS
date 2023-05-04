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
    let fileName: String?
    
    /// The instruction contained in this context.
    private(set) var instructions: [Int: Instruction] = [:]
    
    var end = 0
    /// The included context objects.
    var included: [Context] = []
    /// The inherited context objects.
    var inherited: [Context] = []
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
    func addIdentifier(begin: Int, name: String, type: TypeProto, _ kind: ASTType) {
        instructions[begin] = Definition(begin: begin, returnType: type, name: name, kind: kind)
    }
    
    /// Adds a function to this scope. The given parameters are
    /// added to the subcontext of the added function definition.
    ///
    /// - Parameters:
    ///   - begin: The beginning position of the function definition.
    ///   - scopeBegin: The beginning position of the function's scope.
    ///   - name: The name of the function.
    ///   - returnType: The return type of the function.
    ///   - parameters: The parameter definitions.
    ///   - variadic: Indicates whether the function has variadic parameters.
    /// - Returns: The subscope context object of the function's body.
    func addFunction(begin:      Int,
                     scopeBegin: Int,
                     name:       ASTName,
                     returnType: TypeProto,
                     parameters: [Definition],
                     variadic: Bool) -> Context {
        instructions[begin] = FunctionDefinition(begin:      begin,
                                                 name:       name.name ?? "<< unknown >>",
                                                 returnType: returnType,
                                                 parameters: parameters,
                                                 variadic:   variadic)
        
        let newContext = pushScope(begin: scopeBegin)
        parameters.forEach {
            newContext.addIdentifier(begin: $0.begin, name: $0.name, type: $0.returnType, $0.kind)
        }
        return newContext
    }
    
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
    
    func queryEnclosingFunction() -> FunctionDefinition? {
        guard let parent else { return nil }
        
        if let previous   = Array(parent.instructions.keys).sorted(by: <).last(where: { $0 < begin }),
           let definition = parent.instructions[previous] as? FunctionDefinition {
            return definition
        } else {
            return parent.queryEnclosingFunction()
        }
    }
    
    func inheritsFrom(file: String) -> Bool {
        for inherit in inherited {
            if inherit.fileName == file || inherit.inheritsFrom(file: file) {
                return true
            }
        }
        return false
    }
}
