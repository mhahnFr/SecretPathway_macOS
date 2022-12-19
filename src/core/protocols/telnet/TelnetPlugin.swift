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

import Foundation

/// This plugin adds telnet functionality.
class TelnetPlugin: ProtocolPlugin {
    /// An enumeration with telnet codes defined by the IANA.
    enum Code: UInt8 {
        case binary_transmission = 0
        case echo
        
        case terminal_type = 24
        case eor
        
        case charset = 42
        
        case start_tls = 46
        
        
        case SE = 240
        case SB = 250
        case WILL, WONT, DO, DONT, IAC
    }
    
    private var last: Code?
    private var buffer = (code: Code.IAC, data: Data())
    
    internal func isBegin(byte: UInt8) -> Bool {
        let result = byte == 0xff
        if result {
            last = nil
        }
        return result
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        print(byte)
        var result = false
        
        switch last {
        case .charset:
            if byte == Code.IAC.rawValue {
                last = .IAC
            } else {
                buffer.data.append(byte)
            }
            result = true
            
        default:
            if let code = Code(rawValue: byte) {
                switch code {
                case .SE:
                    interpretBuffer(buffer, sender: sender)
                    result = false
                    
                case .SB, .WILL, .WONT, .DO, .DONT:
                    last = code
                    result = true
                    
                case .charset:
                    switch last {
                    case .DO:   send(codes: .WILL, .charset, sender: sender)
                    case .WILL: send(codes: .DO,   .charset, sender: sender)
                    case .SB:
                        buffer.code = .charset
                        buffer.data = Data()
                        last = code
                        result = true
                    default:
                        print("Unrecognized1")
                    }
                    
                default:
                    switch last {
                    case .WILL:
                        send(codes: .DONT, code, sender: sender)
                        
                    case .DO:
                        send(codes: .WONT, code, sender: sender)
                        
                    default:
                        print("unrecognized2")
                    }
                }
            }
        }
        
        return result
    }
    
    private func interpretBuffer(_ buffer: (code: Code, data: Data), sender: ConnectionSender) {
        switch buffer.code {
        case .charset:
            let command = buffer.data.first!
            if command == 1 {
                let separator = buffer.data[1]
                if String(bytes: buffer.data.advanced(by: 2), encoding: .ascii)!.split(separator: Character(UnicodeScalar(separator))).contains("UTF-8") {
                    var data = Data()
                    data.append(1)
                    data.append("UTF-8".data(using: .ascii)!)
                    send(codes: .SB, .charset, payload: data, sender: sender)
                } else {
                    print("NAC")
                }
            }
            
        default:
            print("Unrecognized3")
        }
    }
    
    private func send(codes: Code..., payload: Data = Data(), sender: ConnectionSender) {
        var data = Data()
        
        data.append(Code.IAC.rawValue)
        print("\(Code.IAC) ", terminator: "")
        for code in codes {
            data.append(code.rawValue)
            print("\(code) ", terminator: "")
        }
        data.append(payload)
        if codes.first! == .SB {
            data.append(Code.IAC.rawValue)
            data.append(Code.SE.rawValue)
            print("\(Code.IAC) \(Code.SE)", terminator: "")
        }
        print("")
        sender.send(data: data)
    }
}
