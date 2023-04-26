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

/// This class represents mutliple following strings as an AST node.
class ASTStrings: ASTExpression {
    /// The list with the actual strings.
    let strings: [ASTExpression]
    
    /// The concatenated strings.
    var value: String {
        var buffer = ""
        
        strings.forEach {
            if let s = $0 as? ASTString {
                buffer.append(s.value)
            }
        }
        
        return buffer
    }
    
    /// Constructs this AST node using the given strings.
    ///
    /// - Parameter strings: The strings.
    init(strings: [ASTExpression]) {
        self.strings = strings
        
        super.init(begin: strings.first!.begin, end: strings.last!.end, type: .STRINGS)
    }
    
    override func describe(_ indentation: Int) -> String {
        var buffer = "\(super.describe(indentation)) Strings:\n"
        
        strings.forEach { buffer.append("\($0.describe(indentation + 4))\n") }
        
        return buffer
    }
    
    override func visit(_ visitor: ASTVisitor) async {
        if await visitor.maybeVisit(self) {
            for string in strings { await string.visit(visitor) }
        }
    }
}
