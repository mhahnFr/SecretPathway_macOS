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

class Interpreter: ASTVisitor {
    private(set) var highlights: [Highlight]
    
    private var current: Context
    private var currentType: TypeProto
    
    init() {
        self.highlights  = []
        self.current     = Context()
        self.currentType = InterpreterType.any
    }
    
    func createContext(for ast: [ASTExpression]) -> Context {
        highlights = []
        current    = Context()
        
        ast.forEach { $0.visit(self) }
        return current
    }
    
    internal func visit(_ expression: ASTExpression) {
        var highlight = true
        
        switch expression.type {
        case .MISSING:
            highlights.append(MessagedHighlight(begin:   expression.begin,
                                                end:     expression.end,
                                                type:    ASTType.MISSING,
                                                message: (expression as! ASTMissing).message))
            highlight = false
            
        case .WRONG:
            highlights.append(MessagedHighlight(begin:   expression.begin,
                                                end:     expression.end,
                                                type:    ASTType.WRONG,
                                                message: (expression as! ASTWrong).message))
            highlight = false
            
        default: currentType = InterpreterType.void
        }
        if highlight {
            highlights.append(ASTHighlight(node: expression))
        }
    }
    
//    internal func visitType(_ type: ASTType) -> Bool {
//        type != .BLOCK               &&
//        type != .FUNCTION_DEFINITION &&
//        type != .VARIABLE_DEFINITION &&
//        type != .OPERATION           &&
//        type != .CAST                &&
//        type != .UNARY_OPERATOR      &&
//        type != .AST_IF              &&
//        type != .AST_RETURN          &&
//        type != .FUNCTION_REFERENCE  &&
//        type != .FUNCTION_CALL
//    }
}
