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

import Network
import Foundation
import SwiftUI

class ClientConnection: ObservableObject {
    private var connection: NWConnection
    private var buffer: String
    private var escaped: Bool
    private var bf: String
    @Published var boundText: String
    @Published var boundPrompt: String
    
    init(_ host: String, port: Int) {
        connection = NWConnection(host: NWEndpoint.Host.init(host), port: NWEndpoint.Port.init(rawValue: UInt16(port))!, using: .tcp)
        // TODO Error handling
        connection.start(queue: .init(label: "Connection"))
        buffer = "";
        bf = ""
        escaped = false
        boundText = ""
        boundPrompt = ""
        receive()
    }
    
    convenience init() {
        self.init(Settings.shared.host, port: Settings.shared.port)
    }
    
    func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10000) { (data, context, completed, error) in
            if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.parseData(str)
                    }
                }
            }
            if !completed {
                self.receive()
            }
        }
    }
    
    func parsePromptPwd(_ args: [Substring]) {
        parsePrompt(args)
        // TODO Switch the textfield
    }
    
    func parseSmalltalk(_ args: [Substring]) {
        parsePrompt(args)
        // TODO switch the textfield
        if (args.count > 1) {
            // TODO
            // boundField = String(data: Data(base64Encoded: String(args[1]))!, encoding: .utf8)!
        }
    }
    
    func parsePrompt(_ args: [Substring]) {
        boundPrompt = String(data: Data(base64Encoded: String(args[0]))!, encoding: .utf8)!
    }
    
    func parseEscaped(_ str: String) {
        // TODO
        var splits = str.split(separator: ":", omittingEmptySubsequences: true)
        let command = splits[0]
        splits.removeFirst()
        switch command {
        case "prompt/plain":     parsePrompt(splits);    break
        case "prompt/smalltalk": parseSmalltalk(splits); break
        case "prompt/password":  parsePromptPwd(splits); break
        default:
            print("Unrecognized escape code!")
        }
    }
    
    func parseData(_ str: String) {
        for c in str {
            if c.asciiValue! == 3 {
                escaped = false
                parseEscaped(buffer)
            } else if c.asciiValue! == 2 {
                escaped = true
                buffer = ""
            } else if escaped {
                buffer.append(c)
            } else {
                bf.append(c)
                print(c, separator: "", terminator: "")
            }
        }
        boundText.append(bf)
        bf = ""
    }
    
    func send(string data2: String) {
        let data = data2 + "\n"
        connection.send(content: data.data(using: .utf8), isComplete: true, completion: .contentProcessed({ (error) in
            if let error = error {
                self.showError(error.debugDescription)
            }
        }))
    }
    
    func showError(_ text: String) {
        // TODO highlight
        boundText.append(text)
    }
    
    func close() {
        connection.cancel()
    }
    
    deinit {
        close()
    }
}
