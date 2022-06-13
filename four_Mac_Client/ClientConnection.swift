//
//  ClientConnection.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 11.06.22.
//

import Network
import Foundation

class ClientConnection {
    private var connection: NWConnection
    private var buffer: String
    private var escapeStart: Character
    private var escapeEnd: Character
    private var escaped: Bool
    
    init(_ host: String, port: Int) {
        connection = NWConnection(host: NWEndpoint.Host.init(host), port: NWEndpoint.Port.init(rawValue: UInt16(port))!, using: .tcp)
        // TODO Error handling
        connection.start(queue: .main)
        buffer = "";
        escapeStart = Character(UnicodeScalar(0x02)!)
        escapeEnd = Character(UnicodeScalar(0x03)!)
        escaped = false
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
            if c == escapeEnd {
                parseEscaped(buffer)
            } else if c == escapeStart {
                buffer = ""
            } else if escaped {
                buffer.append(c)
            } else {
                print(c) // TODO
            }
        }
    }
    
    func close() {
        connection.cancel()
    }
    
    deinit {
        close()
    }
}
