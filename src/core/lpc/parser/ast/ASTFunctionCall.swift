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

/// This class represents a function call as an AST node.
class ASTFunctionCall: ASTExpression {
    /// The name of the called function.
    let name: ASTExpression
    /// The expressions whose result are passed as parameters.
    let arguments: [ASTExpression]
    
    /// Constructs this function call AST node using the given
    /// name, arguments and the given end position.
    ///
    /// - Parameter name: The name.
    /// - Parameter arguments: The argument expressions.
    /// - Parameter end: The end position.
    /// - Parameter type: The type of this expression.
    init(name:      ASTExpression,
         arguments: [ASTExpression],
         end:       Int,
         type:      ASTType = .FUNCTION_CALL) {
        self.name      = name
        self.arguments = arguments
        
        super.init(begin: name.begin, end: end, type: type)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) function name:\n" +
        "\(name.describe(indentation + 4))\n" +
        "\(String(repeating: " ", count: indentation))arguments:\n"
        
        arguments.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await name.visit(visitor)
            
            for argument in arguments {
                await argument.visit(visitor)
            }
        }
    }
}
