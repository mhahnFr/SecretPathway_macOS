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

/// This class defines the base for LPC file managers.
/// Do instantiate this class directly, use a subclass implementation!
class LPCFileManager {
    /// A mapping of the file names to their cached context.
    private var cachedContexts: [String: Context] = [:]
    
    /// Loads the file whose name is given.
    ///
    /// Returns `nil` on error.
    /// Subclasses should override this method.
    ///
    /// - Parameter name: The name of the desired file.
    /// - Returns: The content of the file or `nil` on error.
    func load(file name: String) async -> String? { nil }
    
    /// Loads the indicated file and parses its content.
    ///
    /// Uses a cache to avoid loading and parsing the same file twice.
    ///
    /// - Parameter name: The name of the desired file.
    /// - Returns: The interpretation context or `nil` if the file could not be loaded.
    func loadAndParse(file name: String) async -> Context? {
        if let context = cachedContexts[name] {
            return context
        }
        return await loadAndParseIntern(file: name)
    }
    
    /// Loads and parses the content of the file whose name is given.
    ///
    /// Does not use caching. Returns `nil` if the file could not be loaded.
    ///
    /// - Parameter name: The name of the desired file.
    /// - Returns: The interpretation context or `nil` if the file could not be loaded.
    private func loadAndParseIntern(file name: String) async -> Context? {
        guard let content = await load(file: name) else { return nil }
        var parser  = Parser(text: content)
        let context = await Interpreter(loader: self).createContext(for: parser.parse(), file: name)
        cachedContexts[name] = context
        return context
    }
    
    /// Saves the given file.
    ///
    /// Subclasses should override this method.
    ///
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - content: The new content of the file.
    func save(file name: String, content: String) {
        fatalError("Not implemented")
    }
    
    /// Returns whether compilation functionality is supported
    /// by this file manager.
    ///
    /// - Returns: Whether compilation is supported by this manager.
    func canCompile() -> Bool { false }
    
    /// Compiles the file indicated by the given name.
    ///
    /// - Parameter name: The name of the file.
    func compile(file name: String) {
        fatalError("Not implemented! Hint: Check using LPCFileManager#canCompile()")
    }
    
    func exists(file: String) async -> Bool { false }
}
