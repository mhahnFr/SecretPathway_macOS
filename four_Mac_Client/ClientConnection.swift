//
//  ClientConnection.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 11.06.22.
//

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
    
    func parsePrompt(_ args: [Substring]) {
        boundPrompt = String(data: Data(base64Encoded: String(args[0]))!, encoding: .utf8)!
    }
    
    func parseEscaped(_ str: String) {
        // TODO
        var splits = str.split(separator: ":", omittingEmptySubsequences: true)
        let command = splits[0]
        splits.removeFirst()
        switch command {
        case "prompt/plain":
            parsePrompt(splits)
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
