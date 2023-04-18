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

/// This enumeration contains the possible types of AST nodes.
enum ASTType {
    /// Represents a combination of AST nodes.
    case COMBINATION,
    /// Represents a function definition.
    FUNCTION_DEFINITION,
    /// Represents an include statement.
    AST_INCLUDE,
    /// Represents an inherit statement.
    AST_INHERITANCE,
    /// Represents a missing AST node.
    MISSING,
    /// Represents a parameter declaration.
    PARAMETER,
    /// Represents a variable definition.
    VARIABLE_DEFINITION,
    /// Represents a wrong AST node.
    WRONG,
    /// Represents an ellipsis.
    AST_ELLIPSIS,
    /// Represents a type.
    TYPE,
    /// Represents a name.
    NAME,
    /// Represents a modifier.
    MODIFIER,
    /// Represents a block of code.
    BLOCK,
    /// Represents a break.
    AST_BREAK,
    /// Represents a continue.
    AST_CONTINUE,
    /// Represents a return statement.
    AST_RETURN,
    /// Represents a unary operator.
    UNARY_OPERATOR,
    /// Represents a binary operation.
    OPERATION,
    /// Represents a function call.
    FUNCTION_CALL,
    /// Represents a new expression.
    AST_NEW,
    /// Represents a cast expression.
    CAST,
    /// Represents a "this" expression.
    AST_THIS,
    /// Represents a nil expression.
    AST_NIL,
    /// Represents an integer expression.
    AST_INTEGER,
    /// Represents a string expression.
    AST_STRING,
    /// Represents a symbol expression.
    AST_SYMBOL,
    /// Represents a boolean expression.
    AST_BOOL,
    /// Represents an array expression.
    ARRAY,
    /// Represents a mapping expression.
    AST_MAPPING,
    /// Represents a subscript expression.
    SUBSCRIPT,
    /// Represents a {@code if} statement.
    AST_IF,
    /// Represents a {@code while} statement.
    AST_WHILE,
    /// Represents a {@code do while} statement.
    DO_WHILE,
    /// Represents a regular {@code for} loop.
    AST_FOR,
    /// Represents a {@code foreach} statement.
    AST_FOREACH,
    /// Represents an empty statement.
    EMPTY,
    /// Represents a {@code try catch} statement.
    TRY_CATCH,
    /// Represents a {@code default} case.
    AST_DEFAULT,
    /// Represents a switch case statement.
    AST_CASE,
    /// Represents a switch statement.
    AST_SWITCH,
    /// Represents a class statement.
    AST_CLASS,
    /// Represents a character.
    AST_CHARACTER,
    /// Represents a function reference type.
    FUNCTION_REFERENCE,
    /// Represents an operator identifier.
    OPERATOR_NAME,
    /// Represents a string concatenation.
    STRINGS
}
