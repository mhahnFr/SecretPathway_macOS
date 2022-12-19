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
        
        if let code = Code(rawValue: byte) {
            switch code {
            case .WILL, .WONT, .DO, .DONT:
                result = true
                
            case .charset where last == .DO:
                send(.WILL, .charset, sender)
                
            case .charset where last == .WILL:
                send(.DO, .charset, sender)
                
            default:
                switch last {
                case .WILL:
                    send(.DONT, code, sender)
                    
                case .DO:
                    send(.WONT, code, sender)
                    
                default:
                    print("unrecognized")
                }
            }
            last = code
        }
        
        return result
    }
    
    private func send(_ ack: Code, _ option: Code, _ sender: ConnectionSender) {
        var data = Data()
        
        data.append(Code.IAC.rawValue)
        data.append(ack.rawValue)
        data.append(option.rawValue)
        
        print("\(Code.IAC) \(ack) \(option)")
        sender.send(data: data)
    }
}
