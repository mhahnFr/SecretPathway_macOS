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

/// This class represents a virtual path.
class VPath {
    /// The full name of this path.
    var fullName: String {
        var buffer = ""
        if let parent {
            buffer.append(parent.fullName)
        }
        if !name.isEmpty {
            buffer.append("/\(name)")
        }
        return buffer
    }
    
    /// The parent folder of this path.
    private let parent: VPath?
    /// The name of this folder.
    private let name: String
    /// Indicates whether this path is absolute.
    private let absolute: Bool
    
    /// Constructs a path from the given path string.
    ///
    /// - Parameter from: The path string.
    init(from: String) {
        var tmp = VPath("", absolute: true)
        from.split(whereSeparator: { $0 == "/" }).forEach {
            let name = String($0)
            switch name {
            case "..":     tmp = tmp.parent ?? tmp
            case ".", "":  break
                
            default:       tmp = VPath(name, parent: tmp)
            }
        }
        self.parent   = tmp.parent
        self.name     = tmp.name
        self.absolute = from.first == "/"
    }
    
    /// Constructs this instance using the given arguments.
    ///
    /// - Parameters:
    ///   - name: The name of this folder.
    ///   - absolute: Indicates whether this path is absolute.
    ///   - parent: The parent folder.
    init(_ name: String, absolute: Bool = false, parent: VPath? = nil) {
        self.parent   = parent
        self.name     = name
        self.absolute = absolute
    }
    
    /// Creates and returns a path that is relative to the given path string.
    ///
    /// - Parameter from: The path string.
    /// - Returns: The relative path.
    func relative(_ from: String) -> VPath {
        guard from.first != "/" else { return VPath(from: from) }
        
        var tmp = self
        from.split(whereSeparator: { $0 == "/" }).forEach {
            let name = String($0)
            switch name {
            case "..": tmp = tmp.parent ?? tmp
            case ".", "": break
                
            default: tmp = VPath(name, parent: tmp)
            }
        }
        return tmp
    }
}
