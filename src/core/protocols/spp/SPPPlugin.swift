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
    /// Indicates whether the SP protocol is active.
    var active = false
    var connectionAvailable = true {
        didSet {
            if !connectionAvailable {
                syncer.sync {
                    for (id, (file, _, _)) in fetchList {
                        fetchList.updateValue((file, nil, true), forKey: id)
                    }
                    for (id, (file, _)) in existsList {
                        existsList.updateValue((file, false), forKey: id)
                    }
                    if defaultInheritance == nil {
                        defaultInheritance = ""
                    }
                }
            }
        }
    }
    
    /// The sender this plugin is bound to.
    private let sender: ConnectionSender
    /// The dispath queue used for synchronizing the file fetchers.
    private let syncer = DispatchQueue(label: "spp-plugin-synchronization")
    
    /// The buffer for a message in the SPP.
    private var buffer: [UInt8] = []
    /// The list used for fetching files using the SPP.
    private var fetchList: [UUID: (file: String, content: String?, error: Bool)] = [:]
    private var existsList = [UUID: (file: String, exists: Bool?)]()
    private var defaultInheritance = String?.none
    
    /// Initializes this plugin using the given sender.
    ///
    /// - Parameter sender: The sender used for the protocol's functionality.
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
        case "prompt":      sender.prompt = remainder.isEmpty ? nil : String(remainder)
        case "file":        handleFileCommand(remainder)
        case "editor":      handleEditorCommand(remainder)
        default:            print("Unrecognized command: \"\(message)\"")
        }
    }
    
    /// Handles editor commands.
    ///
    /// - Parameter message: The editor message to process.
    private func handleEditorCommand(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let path    = message[..<index]
        let content = message[message.index(after: index)...]
        sender.openEditor(file: path.isEmpty ? nil : String(path), content: content.isEmpty ? nil : String(content))
    }
    
    /// Handles a prompt command of the SPP.
    ///
    /// - Parameter message: The prompt command.
    private func handlePromptCommand(_ message: any StringProtocol) {
        switch String(message) {
        case "normal":   sender.passwordMode = false
        case "password": sender.passwordMode = true
        default:         print("Unrecognized prompt command: \"\(message)\"")
        }
    }
    
    /// Handles a file command.
    ///
    /// - Parameter message: The file command.
    private func handleFileCommand(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let code      = message[..<index]
        let remainder = message[message.index(after: index)...]
        switch String(code) {
        case "fetch":              putFetchedFile(remainder)
        case "error":              putErrorFile(remainder)
        case "exists":             putExistsFile(remainder)
        case "defaultInheritance": putDefaultInheritance(remainder)
        default:                   print("Unrecognized file command: \"\(message)\"")
        }
    }
    
    private func putDefaultInheritance(_ message: any StringProtocol) {
        syncer.sync {
            defaultInheritance = String(message)
        }
    }
    
    private func putExistsFile(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let name      = message[..<index]
        let existance = message[message.index(after: index)...]
        
        setExistsValue(file: name, existance.lowercased() == "yes")
    }
    
    private func setExistsValue(file name: any StringProtocol, _ exists: Bool) {
        syncer.sync {
            for (id, (fileName, _)) in existsList {
                if fileName == name {
                    existsList.updateValue((fileName, exists), forKey: id)
                }
            }
        }
    }
    
    /// Puts the given file message into the file fetching list.
    ///
    /// - Parameter message: The file command.
    private func putFetchedFile(_ message: any StringProtocol) {
        guard let index = message.firstIndex(of: ":") else { return }
        
        let name    = message[..<index]
        let content = message[message.index(after: index)...]
        
        setFetchedValue(file: name, value: String(content))
    }
    
    /// Puts the given file message as error into the file fetching list.
    ///
    /// - Parameter message: The file command.
    private func putErrorFile(_ message: any StringProtocol) {
        setFetchedValue(file: message, value: nil, error: true)
    }
    
    /// Sets a value in the fetching list.
    ///
    /// This method synchronizes the fetching list using the main dispatch queue.
    ///
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - value: The content of the file or `nil`.
    ///   - error: Indicates whether an error occurred while fetching the file.
    private func setFetchedValue(file name: any StringProtocol, value: String?, error: Bool = false) {
        syncer.sync {
            for (id, (fileName, _, _)) in fetchList {
                if fileName == name {
                    fetchList.updateValue((fileName, value, error), forKey: id)
                }
            }
        }
    }
    
    /// Sends the given message in the SP protocol.
    ///
    /// - Parameter message: The message to be sent.
    private func send(_ message: String) {
        guard let messageBytes = message.data(using: .utf8) else { return }
        
        var sendBytes = Data(capacity: messageBytes.count + 3)
        
        sendBytes.append(0x02)
        sendBytes.append(messageBytes)
        sendBytes.append(contentsOf: [0x03, ("\n" as Character).asciiValue!])
        
        sender.send(data: sendBytes)
    }
    
    /// Saves the file with the given content.
    ///
    /// - Parameters:
    ///   - name: The file name.
    ///   - content: Th file content.
    func save(file name: String, content: String) {
        send("file:store:\(name):\(content)")
    }
    
    /// Sends a compilation request to the server.
    ///
    /// - Parameter name: The name of the file to be compiled.
    func compile(file name: String) {
        send("file:compile:\(name)")
    }
    
    /// Adds a fetcher to the fetching list.
    ///
    /// This method synchronizes the usage of the fetching list
    /// using the main dispatch queue.
    ///
    /// - Parameters:
    ///   - id: The id of the fetcher.
    ///   - name: The name of the file to be fetched.
    private func addFetcher(id: UUID, file name: String) {
        syncer.sync {
            fetchList[id] = (file: name, content: nil, error: false)
        }
    }
    
    /// Returns whether the fetcher with the given id should still wait for
    /// a response.
    ///
    /// The usage of the fetching list is synchronized using the main
    /// dispatch queue.
    ///
    /// - Parameter id: The fetcher id.
    /// - Returns: Whether the fetcher still has to wait for a response.
    private func fetcherWaiting(id: UUID) -> Bool {
        var ret = true
        
        syncer.sync {
            if let fetch = fetchList[id] {
                ret = fetch.content == nil && !fetch.error
            }
        }
        
        return ret
    }
    
    /// Returns and removes the content associated with the fetcher
    /// of the given id.
    ///
    /// The usage of the fetching list is synchronized using the main
    /// dispatch queue.
    ///
    /// - Parameter id: The fetcher id.
    /// - Returns: The content associated with the fetcher.
    private func getFetcher(id: UUID) -> (file: String, content: String?, error: Bool) {
        var ret = ("", String?.none, true)
        
        syncer.sync {
            if let result = fetchList[id] {
                ret = result
                fetchList.removeValue(forKey: id)
            }
        }
        
        return ret
    }
    
    private func addExistsFetcher(id: UUID, file name: String) {
        syncer.sync {
            existsList[id] = (file: name, exists: nil)
        }
    }
    
    private func existsFetcherWaiting(id: UUID) -> Bool {
        var ret = true
        
        syncer.sync {
            if let fetch = existsList[id] {
                ret = fetch.exists == nil
            }
        }
        
        return ret
    }
    
    private func getExistsFetcher(id: UUID) -> (file: String, exists: Bool?) {
        var ret = ("", Bool?.none)
        
        syncer.sync {
            if let result = existsList[id] {
                ret = result
                existsList.removeValue(forKey: id)
            }
        }
        
        return ret
    }
    
    func exists(file name: String) async -> Bool {
        guard connectionAvailable else { return false }
        
        let id = UUID()
        addExistsFetcher(id: id, file: name)
        send("file:exists:\(name)")
        let startTime = Date()
        while existsFetcherWaiting(id: id) && startTime.timeIntervalSinceNow > -5 {
            try? await Task.sleep(nanoseconds: 100_000)
        }
        return getExistsFetcher(id: id).exists ?? false
    }
    
    /// Fetches the file of the given name.
    ///
    /// - Parameter name: The name of the file to be fetched.
    /// - Returns: The content of the file or `nil` if an error occurred.
    func fetch(file name: String) async -> String? {
        guard connectionAvailable else { return nil }
        
        let id = UUID()
        addFetcher(id: id, file: name)
        send("file:fetch:\(name)")
        let startTime = Date()
        while fetcherWaiting(id: id) && startTime.timeIntervalSinceNow > -5 {
            try? await Task.sleep(nanoseconds: 100_000)
        }
        return getFetcher(id: id).content
    }
    
    private func diWaiting() -> Bool {
        var ret = true
        
        syncer.sync {
            ret = defaultInheritance == nil
        }
        
        return ret
    }
    
    private func getDefaultInheritanceImpl() -> String? {
        var ret = String?.none
        
        syncer.sync {
            ret = defaultInheritance
        }
        
        return ret
    }
    
    func getDefaultInheritance() async -> String? {
        guard connectionAvailable else { return nil }
        
        if let defaultInheritance = getDefaultInheritanceImpl() { return defaultInheritance }
        
        send("file:defaultInheritance:")
        let startTime = Date()
        while diWaiting() && startTime.timeIntervalSinceNow > -5 {
            try? await Task.sleep(nanoseconds: 100_000)
        }
        return getDefaultInheritanceImpl()
    }
}
