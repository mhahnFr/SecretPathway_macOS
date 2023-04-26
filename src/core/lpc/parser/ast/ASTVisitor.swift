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

/// This protocol defines an AST visitor.
protocol ASTVisitor {
    /// Visits the given expression.
    ///
    /// - Parameter expression: The expression to be visited.
    func visit(_ expression: ASTExpression) async
    
    /// Returns whether the given type should be visited
    /// in depth.
    ///
    /// - Parameter type: The type in question.
    /// - Returns: Whether the given type should be visited in depth.
    func visitType(_ type: ASTType) -> Bool
    
    /// Visits the given expression and returns whether to
    /// visit contained nodes.
    ///
    /// - Parameter expression: The expression to be visited.
    /// - Returns: Whether to visit contained nodes.
    func maybeVisit(_ expression: ASTExpression) async -> Bool
}

/// This extension implements a default behaviour for the AST visitor.
extension ASTVisitor {
    
    func visitType(_ type: ASTType) -> Bool {
        return true
    }
    
    func maybeVisit(_ expression: ASTExpression) async -> Bool {
        await visit(expression)
        return visitType(expression.type)
    }
}
