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

/// This class represents an array type as an AST node.
class ArrayType: AbstractType, ArrayTypeProto {
    /// The type of the content of this array.
    let underlyingType: ASTExpression
    let underlying: TypeProto?
    
    var string: String {
        if let underlying = TypeHelper.unwrap(underlyingType) {
            return "\(underlying.string)[]"
        }
        return "<< unknown >> []"
    }
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter underlyingType: The underlying type.
    /// - Parameter end: The end position.
    init(underlyingType: ASTExpression, end: Int) {
        self.underlyingType = underlyingType
        self.underlying     = TypeHelper.unwrap(underlyingType)
        
        super.init(begin: underlyingType.begin, end: end, type: .ARRAY_TYPE)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) underlying type:\n\(underlyingType.describe(indentation + 4))"
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            await underlyingType.visit(visitor)
        }
    }
}
