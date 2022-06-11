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
    
    init(_ host: String, port: Int) {
        connection = NWConnection(host: NWEndpoint.Host.init(host), port: NWEndpoint.Port.init(rawValue: UInt16(port))!, using: .tcp)
        // TODO Error handling
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 85, maximumLength: 1000000) { (data, _, comleted, error) in
            if let data = data {
                print("Processing data...")
                print(data.count)
                print(comleted)
//                let tmpData = Data(base64Encoded: data)!
//                let str = String(data: tmpData, encoding: .utf8)
                print("Finished")
            }
        }
    }
    
    convenience init() {
        self.init(Settings.shared.host, port: Settings.shared.port)
    }
    
    deinit {
        close()
    }
    
    func close() {
        connection.cancel()
    }
}
