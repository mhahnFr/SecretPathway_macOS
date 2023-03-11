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

class ASTCombination: ASTExpression {
    let expressions: [ASTExpression]
    
    init(_ expressions: [ASTExpression]) {
        self.expressions = expressions
        
        super.init(begin: expressions.first!.begin, end: expressions.last!.end, type: .COMBINATION)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = super.describe(indentation) + "\n"
        
        for expression in expressions {
            buffer.append(expression.describe(indentation + 4) + "\n")
        }
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            expressions.forEach { $0.visit(visitor) }
        }
    }
}
