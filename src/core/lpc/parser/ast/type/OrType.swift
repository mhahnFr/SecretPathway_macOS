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

class OrType: AbstractType, OrTypeProto {
    let lhs: TypeProto?
    let rhs: TypeProto?
    
    let lhsExpression: ASTExpression
    let rhsExpression: ASTExpression
    
    init(lhs: ASTExpression, rhs: ASTExpression) {
        self.lhs = TypeHelper.unwrap(lhs)
        self.rhs = TypeHelper.unwrap(rhs)
        
        self.lhsExpression = lhs
        self.rhsExpression = rhs
        
        super.init(begin: lhs.begin, end: rhs.end, type: .OR_TYPE)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) left type:\n"                +
        "\(lhsExpression.describe(indentation + 4))\n"               +
        "\(String(repeating: " ", count: indentation))right type:\n" +
        "\(rhsExpression.describe(indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await lhsExpression.visit(visitor)
            await rhsExpression.visit(visitor)
        }
    }
}
