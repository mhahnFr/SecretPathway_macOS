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

/// This class represents a new expression as an AST node.
class ASTNew: ASTFunctionCall {
    /// The instancing expression.
    let instancingExpression: ASTExpression
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter instancingExpression: The instancing expression.
    /// - Parameter arguments: The optional argument expressions.
    init(begin:                Int,
         end:                  Int,
         instancingExpression: ASTExpression,
         arguments:            [ASTExpression]) {
        self.instancingExpression = instancingExpression
        
        var subs = [instancingExpression]
        subs.append(contentsOf: arguments)
        super.init(name:      ASTName(token: Token(begin:   begin,
                                                   type:    .STRING,
                                                   payload: "new",
                                                   end:     instancingExpression.end)),
                   arguments: arguments,
                   end:       end,
                   type:      .AST_NEW,
                   subNodes:  subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(String(repeating: " ", count: indentation))\(type) [\(begin) - \(end)] what:\n" +
                     "\(instancingExpression.describe(indentation + 4))\n"
        buffer.append("\(String(repeating: " ", count: indentation))arguments:\n")
        arguments.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await instancingExpression.visit(visitor)
            for argument in arguments { await argument.visit(visitor) }
        }
    }
}
