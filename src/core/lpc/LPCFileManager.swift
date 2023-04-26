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

class LPCFileManager {
    var cachedContexts: [String: Context] = [:]
    
    func load(file name: String) async -> String? { nil }
    
    func loadAndParse(file name: String) async -> Context? {
        if let context = cachedContexts[name] {
            return context
        }
        return await loadAndParseIntern(file: name)
    }
    
    private func loadAndParseIntern(file name: String) async -> Context? {
        guard let content = await load(file: name) else { return nil }
        var parser  = Parser(text: content)
        let context = Interpreter().createContext(for: parser.parse())
        cachedContexts[name] = context
        return context
    }
    
    func save(file name: String, content: String) {
        fatalError("Not implemented")
    }
    
    func canCompile() -> Bool { false }
    
    func compile(file name: String) {
        fatalError("Not implemented! Hint: Check using LPCFileManager#canCompile()")
    }
}
