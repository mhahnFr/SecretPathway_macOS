/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2022 - 2023  mhahnFr
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

/// Instances of this class act as a protocol provider.
///
/// It consists of the possibility to add various plugins and maintains a
/// state machine which protocol should be used.
///
/// Although new plugins can be added any time, they cannot be removed.
class Protocols {
    /// The array of the plugins.
    private var plugins: [ProtocolPlugin] = []
    /// The plugin currently responsible for handling input.
    private var lastPlugin: ProtocolPlugin?
    
    /// A reference to a sender in order for the plugins to send responses.
    private unowned(unsafe) let sender: ConnectionSender
    
    /// Initializes this instance using the given connection sender.
    ///
    /// - Parameter sender: The sender to be used by the plugins to send responses.
    init(sender: ConnectionSender) {
        self.sender = sender
    }
    
    /// Initializes this instance using the given connection sender and the given plugins.
    ///
    /// - Parameter sender: The sender to be used by the plugins to send responses.
    /// - Parameter plugins: The plugins to store right away.
    init(sender: ConnectionSender, plugins: ProtocolPlugin...) {
        self.sender  = sender
        self.plugins = plugins
    }
    
    /// Adds the given plugin to the list of used plugins.
    ///
    /// - Parameter plugin: The new plugin to be appended.
    func add(plugin: ProtocolPlugin) {
        plugins.append(plugin)
    }
    
    /// Processes the given byte of input.
    ///
    /// If the internal state machine is in the state of a plugin being responsible
    /// for processing incoming data, the byte is passed to that plugin.
    /// Otherwise, all plugins are asked whether they handle the given byte.
    ///
    /// This function is meant to be used in a state machine, so it returns whether
    /// it should keep sending incoming input to this instance.
    ///
    /// - Parameter byte: The incoming byte.
    /// - Returns: Whether the next input should be sent to this instance.
    func process(byte: UInt8) -> Bool {
        if let lastPlugin {
            if !lastPlugin.process(byte: byte, sender: sender) {
                self.lastPlugin = nil
                return false
            } else {
                return true
            }
        } else {
            for plugin in plugins {
                if plugin.isBegin(byte: byte) {
                    lastPlugin = plugin
                    return true
                }
            }
        }
        return false
    }
    
    /// Triggers the connection error handler on all registered plugins.
    func onConnectionError() {
        plugins.forEach { $0.onConnectionError() }
    }
}
