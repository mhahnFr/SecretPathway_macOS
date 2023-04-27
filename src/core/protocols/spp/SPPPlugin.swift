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

import Foundation

/// This class adds the SecretPathwayProtocol as a plugin.
class SPPPlugin: ProtocolPlugin {
    var active = false
    
    private let sender: ConnectionSender
    
    /// The buffer for a message in the SPP.
    private var buffer: [UInt8] = []
    
    private var fetchList: [UUID: (file: String, content: String?, error: Bool)] = [:]
    
    init(sender: ConnectionSender) {
        self.sender = sender
    }
    
    internal func isBegin(byte: UInt8) -> Bool {
        return byte == 0x2
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        if byte == 0x03 {
            processBuffer()
            buffer = []
            return false
        }
        buffer.append(byte)
        return true
    }
    
    /// Handles the received SPP message.
    private func processBuffer() {
        guard let message = String(bytes: buffer, encoding: .utf8),
              let index = message.firstIndex(of: ":")
        else { return }
        
        let code      = message[..<index]
        let remainder = message[message.index(after: index)...]
        
        switch code {
        case "promptField": handlePromptCommand(remainder)
        case "file":        handleFileCommand(remainder)
        case "editor":      sender.openEditor(remainder.isEmpty ? nil : remainder)
        default:            print("Unrecognized command: \"\(message)\"")
        }
    }
    
    private func handlePromptCommand(_ message: any StringProtocol) {
        switch String(message) {
        case "normal":   sender.passwordMode = false
        case "password": sender.passwordMode = true
        default:         print("Unrecognized prompt command: \"\(message)\"")
        }
    }
    
    private func handleFileCommand(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let code      = message[..<index]
        let remainder = message[message.index(after: index)...]
        switch String(code) {
        case "fetch": putFetchedFile(remainder)
        case "error": putErrorFile(remainder)
        default:      print("Unrecognized file command: \"\(message)\"")
        }
    }
    
    private func putFetchedFile(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let name    = message[..<index]
        let content = message[message.index(after: index)...]
        
        setFetchedValue(file: name, value: String(content))
    }
    
    private func putErrorFile(_ message: any StringProtocol) {
        setFetchedValue(file: message, value: nil, error: true)
    }
    
    private func setFetchedValue(file name: any StringProtocol, value: String?, error: Bool = false) {
        DispatchQueue.main.sync {
            for (id, (fileName, _, _)) in fetchList {
                if fileName == name {
                    fetchList.updateValue((fileName, value, error), forKey: id)
                }
            }
        }
    }
    
    private func send(_ message: String) {
        guard let messageBytes = message.data(using: .utf8) else { return }
        
        var sendBytes = Data(capacity: messageBytes.count + 3)
        
        sendBytes.append(0x02)
        sendBytes.append(messageBytes)
        sendBytes.append(contentsOf: [0x03, ("\n" as Character).asciiValue!])
        
        sender.send(data: sendBytes)
    }
    
    func save(file name: String, content: String) {
        send("file:store:\(name):\(content)")
    }
    
    func compile(file name: String) {
        send("file:compile:\(name)")
    }
    
    private func addFetcher(id: UUID, file name: String) {
        DispatchQueue.main.sync {
            fetchList[id] = (file: name, content: nil, error: false)
        }
    }
    
    private func fetcherWaiting(id: UUID) -> Bool {
        var ret = true
        
        DispatchQueue.main.sync {
            if let fetch = fetchList[id] {
                ret = fetch.content == nil && !fetch.error
            }
        }
        
        return ret
    }
    
    private func getFetcher(id: UUID) -> (file: String, content: String?, error: Bool) {
        var ret = ("", String?.none, true)
        
        DispatchQueue.main.sync {
            if let result = fetchList[id] {
                ret = result
                fetchList.removeValue(forKey: id)
            }
        }
        
        return ret
    }
    
    func fetch(file name: String) async -> String? {
        let id = UUID()
        addFetcher(id: id, file: name)
        send("file:fetch:\(name)")
        while fetcherWaiting(id: id) {
            await Task.yield()
        }
        let result = getFetcher(id: id).content
        return result
    }
}
