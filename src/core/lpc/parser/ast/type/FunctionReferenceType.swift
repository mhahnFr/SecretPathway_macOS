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

class FunctionReferenceType: AbstractType {
    let returnType: AbstractType
    let parameterTypes: [AbstractType]
    let variadic: Bool
    
    init(returnType: AbstractType, parameterTypes: [AbstractType], variadic: Bool = false, end: Int) {
        self.returnType = returnType
        self.parameterTypes = parameterTypes
        self.variadic = variadic
        
        super.init(begin: returnType.begin, end: end, type: .FUNCTION_REFERENCE)
    }
}
