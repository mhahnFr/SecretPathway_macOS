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
    private var cachedContexts = [String: Context?]()
    /// A mapping of the file names to their existance.
    private var cachedExists   = [String: Bool]()
    
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
    /// - Parameter referrer: The file name from which to resolve the requested file.
    /// - Returns: The interpretation context or `nil` if the file could not be loaded.
    func loadAndParse(file name: String, referrer: String = "") async -> Context? {
        let index = name.firstIndex(of: ":")
        let actualName = String(name[..<(index ?? name.endIndex)])
        if let context = cachedContexts[actualName] {
            return context?.digOutClass(name: name)
        }
        let context = await loadAndParseIntern(file: actualName, referrer: referrer)
        return context?.digOutClass(name: name)
    }
    
    /// Loads and parses the content of the file whose name is given.
    ///
    /// Does not use caching. Returns `nil` if the file could not be loaded.
    ///
    /// - Parameter name: The name of the desired file.
    /// - Parameter referrer: The file name from which to resolve the requested file.
    /// - Returns: The interpretation context or `nil` if the file could not be loaded.
    private func loadAndParseIntern(file name: String, referrer: String) async -> Context? {
        guard let content = await load(file: name) else {
            cachedContexts[name] = Context?.none
            return nil
        }
        var parser  = Parser(text: content)
        let context = await Interpreter(loader: self, referrer: referrer).createBackgroundContext(for: parser.parse(), file: name)
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
        print("Not implemented")
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
    
    /// Returns whether the file indicated by the given name exists.
    ///
    /// - Parameter file: The name of the file to be checked.
    /// - Returns: Whether the file exists.
    func exists(file: String) async -> Bool {
        if file.firstIndex(of: ":") != nil {
            return await loadAndParse(file: file) != nil
        }
        if let cached = cachedExists[file] {
            return cached
        }
        let existance = await existsImpl(file: file)
        cachedExists[file] = existance
        return existance
    }
    
    /// Returns whether the file indicated by the given name exists.
    ///
    /// This method should be overwritten by subclasses.
    ///
    /// - Parameter file: The name of the file to be checked.
    /// - Returns: Whether the file exists.
    func existsImpl(file: String) async -> Bool { false }
    
    /// Returns the file name of the file from which to implicitly inherit.
    ///
    /// - Returns: The name of the default inheritance file.
    func getDefaultInheritance() async -> String? { nil }
}
