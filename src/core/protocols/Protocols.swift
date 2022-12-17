/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022  mhahnFr
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
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
 */

class Protocols {
    private var plugins: [ProtocolPlugin] = []
    
    private var lastPlugin: ProtocolPlugin?
    
    private unowned(unsafe) let sender: ConnectionSender
    
    init(sender: ConnectionSender) {
        self.sender = sender
    }
    
    func add(plugin: ProtocolPlugin) {
        plugins.append(plugin)
    }
    
    func process(byte: UInt8) -> Bool {
        if let lastPlugin {
            if !lastPlugin.process(byte: byte) {
                self.lastPlugin = nil
                return false
            } else {
                return true
            }
        } else {
            for plugin in plugins {
                if plugin.process(byte: byte) {
                    lastPlugin = plugin
                    return true
                }
            }
        }
        return false
    }
}
