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
    
    /// The instruction contained in this context.
    private(set) var instructions: [Int: Instruction] = [:]
    
    var end = 0
    
    /// Constructs this context using the optional beginning position
    /// and the optional parent context.
    ///
    /// - Parameters:
    ///   - begin: The beginning position.
    ///   - parent: The parent context.
    init(begin: Int = 0, parent: Context? = nil) {
        self.begin  = begin
        self.parent = parent
    }
    
    func pushScope(begin: Int) -> Context {
        let newContext = Context(begin: begin, parent: self)
        instructions[begin] = newContext
        return newContext
    }
    
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
}
