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

/// This class represents a `try catch` statement as an AST node.
class ASTTryCatch: ASTExpression {
    /// The try expression.
    let tryExpression: ASTExpression
    /// The catching expression.
    let catchExression: ASTExpression
    /// The optional exception variable.
    let exceptionVariable: ASTExpression?
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter tryExpression: The try expression.
    /// - Parameter catchExpression: The catching expression.
    /// - Parameter exceptionVariable: The optional exception variable.
    init(begin:             Int,
         tryExpression:     ASTExpression,
         catchExression:    ASTExpression,
         exceptionVariable: ASTExpression?) {
        self.tryExpression     = tryExpression
        self.catchExression    = catchExression
        self.exceptionVariable = exceptionVariable
        
        super.init(begin: begin, end: catchExression.end, type: .TRY_CATCH)
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        var buffer = "\(super.describe(indentation)) Try:\n" +
                     "\(tryExpression.describe(indentation + 4))\n"
        
        if let exceptionVariable {
            buffer.append("\(indent)Catching:\n\(exceptionVariable.describe(indentation + 4))")
        }
        
        buffer.append("\(indent)Caught:\n\(catchExression.describe(indentation + 4))")
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await tryExpression.visit(visitor)
            await exceptionVariable?.visit(visitor)
            await catchExression.visit(visitor)
        }
    }
}
