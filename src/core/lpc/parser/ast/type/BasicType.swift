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

/// This class represents a basic type as an AST node.
class BasicType: AbstractType {
    /// The optional type file.
    let typeFile: ASTExpression?
    /// The represented type.
    let representedType: TokenType?
    
    var string: String {
        if let representedType {
            let typeString = TypeHelper.tokenTypeString(representedType)
            if let file = (typeFile as? ASTStrings)?.value {
                return "\(typeString)<\"\(file)\">"
            }
            return "\(typeString)"
        }
        return "<< unknown >>"
    }
    
    /// Constructs this AST node using the given information.
    ///
    /// - Parameter begin: The beginning position.
    /// - Parameter end: The end position.
    /// - Parameter representedType: The type.
    /// - Parameter typeFile: The optional type file.
    init(begin:           Int,
         representedType: TokenType?,
         end:             Int,
         typeFile:        ASTExpression?) {
        self.typeFile        = typeFile
        self.representedType = representedType
        
        super.init(begin: begin, end: end, type: .TYPE)
    }
    
    override func describe(_ indentation: Int) -> String {
        "\(super.describe(indentation)) type: \(representedType?.rawValue ?? "<unknown>")\n" +
        "\(typeFile?.describe(indentation + 4) ?? "")"
    }
    
    override func visit(_ visitor: ASTVisitor) {
        if visitor.maybeVisit(self) {
            typeFile?.visit(visitor)
        }
    }
    
    func isAssignable(from other: TypeProto) -> Bool {
        guard let representedType else { return false }
        
        if representedType == .ANY {
            if let o = other as? BasicType, o.representedType == .VOID {
                return false
            }
            return true
        }
        guard let o = other as? BasicType else { return false }
        if let tf  = (typeFile as? ASTStrings)?.value,
           let otf = (o.typeFile as? ASTStrings)?.value,
           tf != otf {
            return false
        }
        if representedType == .OBJECT ||
           representedType == .STRING ||
           representedType == .SYMBOL_KEYWORD {
            return o.representedType == .OBJECT ||
                   o.representedType == .STRING ||
                   o.representedType == .SYMBOL_KEYWORD
        } else if representedType == .BOOL ||
                  representedType == .INT_KEYWORD {
            return o.representedType == .INT_KEYWORD ||
                   o.representedType == .BOOL
        }
        return o.representedType == representedType
    }
}
