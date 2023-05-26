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

/// This class represents an `if` statement as an AST node.
class ASTIf: ASTExpression {
    /// The condition expression.
    let condition: ASTExpression
    /// The if instruction.
    let instruction: ASTExpression
    /// The optional else instruction.
    let elseInstruction: ASTExpression?
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter condition: The condition expression.
    /// - Parameter instruction: The instruction.
    /// - Parameter elseInstruction: The optional `else` instruction.
    init(begin:           Int,
         condition:       ASTExpression,
         instruction:     ASTExpression,
         elseInstruction: ASTExpression?) {
        self.condition       = condition
        self.instruction     = instruction
        self.elseInstruction = elseInstruction
        
        var subs = [condition, instruction]
        if let elseInstruction { subs.append(elseInstruction) }
        super.init(begin: begin, end: elseInstruction?.end ?? instruction.end, type: .AST_IF, subNodes: subs)
    }
    
    override func describe(_ indentation: Int) -> String {
        let indent = String(repeating: " ", count: indentation)
        
        var buffer = "\(super.describe(indentation)) Condition:\n" +
        "\(condition.describe(indentation + 4))\n" +
        "\(indent)Instruction:\n\(instruction.describe(indentation + 4))"
        
        if let elseInstruction {
            buffer.append("\(indent)Else:\n\(elseInstruction.describe(indentation + 4))")
        }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await condition.visit(visitor)
            await instruction.visit(visitor)
            await elseInstruction?.visit(visitor)
        }
    }
}
