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
    @Published var boundText: String
    @Published var boundPrompt: String
    
    init(_ host: String, port: Int) {
        connection = NWConnection(host: NWEndpoint.Host.init(host), port: NWEndpoint.Port.init(rawValue: UInt16(port))!, using: .tcp)
        // TODO Error handling
        connection.start(queue: .main)
        buffer = "";
        escaped = false
        boundText = ""
        boundPrompt = ""
        receive()
    }
    
    convenience init() {
        self.init(Settings.shared.host, port: Settings.shared.port)
    }
    
    func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10000) { (data, context, comleted, error) in
            if let data = data {
                if let str = String(data: data, encoding: .utf8) {
                    self.parseData(str)
                }
            }
            if !comleted {
                self.receive()
            }
        }
    }
    
    func parseEscaped(_ str: String) {
        // TODO
    }
    
    func parseData(_ str: String) {
        for c in str {
            print("Character: \(c.asciiValue!)")
            if c.asciiValue! == 3 {
                escaped = false
                parseEscaped(buffer)
            } else if c.asciiValue! == 2 {
                escaped = true
                buffer = ""
            } else if escaped {
                buffer.append(c)
            } else {
                boundText.append(c)
            }
        }
    }
    
    func send(string data: String) {
        // TODO
        print(data)
    }
    
    func close() {
        connection.cancel()
    }
    
    deinit {
        close()
    }
}
