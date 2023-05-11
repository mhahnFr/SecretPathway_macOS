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

/// This enum contains highlightable types.
enum HighlightType: String {
    /// An AST type.
    case COMBINATION, FUNCTION_DEFINITION, AST_INCLUDE, AST_INHERITANCE, MISSING,
    PARAMETER, VARIABLE_DEFINITION, WRONG, AST_ELLIPSIS, TYPE, NAME, MODIFIER,
    BLOCK, AST_BREAK, AST_CONTINUE, AST_RETURN, UNARY_OPERATOR, OPERATION,
    FUNCTION_CALL, AST_NEW, CAST, AST_THIS, AST_NIL, AST_INTEGER, AST_STRING,
    AST_SYMBOL, AST_BOOL, ARRAY, AST_MAPPING, SUBSCRIPT, AST_IF, AST_WHILE,
    DO_WHILE, AST_FOR, AST_FOREACH, EMPTY, TRY_CATCH, AST_DEFAULT, AST_CASE,
    AST_SWITCH, AST_CLASS, AST_CHARACTER, FUNCTION_REFERENCE, OPERATOR_NAME,
    STRINGS, ARRAY_TYPE
    
    /// A token type.
    case EOF,
    
    IDENTIFIER, INTEGER, STRING, CHARACTER, SYMBOL,
    
    LEFT_PAREN, RIGHT_PAREN, LEFT_BRACKET, RIGHT_BRACKET, LEFT_CURLY, RIGHT_CURLY,
    DOT, COMMA, SCOPE, COLON, SEMICOLON, ELLIPSIS, RANGE,
    
    EQUALS, NOT_EQUAL, LESS, LESS_OR_EQUAL, GREATER, GREATER_OR_EQUAL,
    
    OR, AND, NOT,
    
    ASSIGNMENT, ARROW, AMPERSAND, PIPE, LEFT_SHIFT, RIGHT_SHIFT,
    DOUBLE_QUESTION, QUESTION,
    
    INCREMENT, DECREMENT,
    
    PLUS, MINUS, STAR, SLASH, PERCENT,
    
    ASSIGNMENT_PLUS, ASSIGNMENT_MINUS, ASSIGNMENT_STAR, ASSIGNMENT_SLASH, ASSIGNMENT_PERCENT,
    
    INCLUDE, INHERIT, PRIVATE, PROTECTED, PUBLIC, OVERRIDE, DEPRECATED, NOSAVE, NEW,
    THIS, NIL, TRUE, FALSE, SIZEOF, IS, CLASS, VOID, CHAR_KEYWORD, INT_KEYWORD,
    BOOL, OBJECT, STRING_KEYWORD, SYMBOL_KEYWORD, MAPPING, ANY, MIXED, AUTO, OPERATOR,
    LET, IF, ELSE, WHILE, DO, FOR, FOREACH, SWITCH, CASE, DEFAULT,
    BREAK, CONTINUE, RETURN, TRY, CATCH,
    
    COMMENT_BLOCK, COMMENT_LINE,

    ASSIGNMENT_BIT_AND, ASSIGNMENT_BIT_OR, ASSIGNMENT_BIT_XOR,
    ASSIGNMENT_L_SHIFT, ASSIGNMENT_R_SHIFT,
    BIT_XOR, BIT_NOT,
    STATIC, FLOAT, EXCEPTION
    
    /// An interpretation highlight type.
    case TYPE_MISMATCH, ERROR, WARNING, NOT_FOUND, NOT_FOUND_BUILTIN, UNRESOLVED
}
