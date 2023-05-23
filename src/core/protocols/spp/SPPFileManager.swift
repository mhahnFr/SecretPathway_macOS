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

/// This class represents an implementation of the LPCFileManager
/// using the SP protocol.
class SPPFileManager: LPCFileManager {
    /// The associated SPP plugin.
    let plugin: SPPPlugin
    
    /// Initializes this file manager using the given SPP plugin.
    ///
    /// - Parameter plugin: The SPP plugin to be used by this manager.
    init(plugin: SPPPlugin) {
        self.plugin = plugin
    }
    
    override func load(file name: String) async -> String? {
        return await plugin.fetch(file: name)
    }
    
    override func save(file name: String, content: String) {
        plugin.save(file: name, content: content)
    }
    
    override func canCompile() -> Bool { true }
    
    override func compile(file name: String) {
        plugin.compile(file: name)
    }
    
    override func existsImpl(file: String) async -> Bool {
        await plugin.exists(file: file)
    }
    
    override func getDefaultInheritance() async -> String? {
        await plugin.getDefaultInheritance()
    }
}
