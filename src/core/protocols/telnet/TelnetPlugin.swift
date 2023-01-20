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

/// This plugin adds telnet functionality.
class TelnetPlugin: ProtocolPlugin {
    /// An enumeration with telnet codes defined by the IANA.
    enum Code: UInt8 {
        case binary_transmission = 0,
             echo,
             reconnection,
             suppress_go_ahead,
             approx_message_size_negotiation,
             status,
             timing_mark,
             rc_trans_echo,
             o_line_width,
             o_page_size,
             o_cr_disposition,
             o_htab_stops,
             o_htab_disposition,
             o_formfeed_disposition,
             o_vtab_stops,
             o_vtab_disposition,
             o_lf_disposition,
             extended_ascii,
             logout,
             byte_macro,
             data_entry_terminal,
             supdup,
             supdup_output,
             send_location,
             terminal_type,
             eor,
             tacacs_user_identification,
             output_marking,
             terminal_location_number,
             telnet_3270_regime,
             x_3_pad,
             naws,
             terminal_speed,
             remote_flow_control,
             linemode,
             x_display_location,
             environment_option,
             authentication_option,
             encryption_option,
             new_environment_option,
             tn3270e,
             xauth,
             charset,
             telnet_rsp,
             com_port_control_option,
             telnet_suppress_local_echo,
             telnet_start_tls,
             kermit,
             send_url,
             forward_x
        
        case telopt_pragma_logon = 138,
             telopt_sspi_logon,
             telopt_pragma_heartbeat
    }
    /// An enumeration of the basic telnet functions.
    enum TelnetFunction: UInt8 {
        case SE = 240
        case SB = 250,
             WILL,
             WONT,
             DO,
             DONT,
             IAC
        
        /// The opposite of this telnet function.
        ///
        /// If it does not have an opposite, it is simply returned.
        var opposite: Self {
            switch self {
            case .WILL: return .DONT
            case .WONT: return .DO
                
            case .DO:   return .WONT
            case .DONT: return .WILL
                
            case .SE: return .SB
            case .SB: return .SE
                
            default: return self
            }
        }
    }
    /// An enumeration containing MUD specific additions
    enum MudExtensions: UInt8 {
        case a = 0
    }
    
    /// Indicates whether the currently received telnet sequence ends with IAC SE.
    private var hasEnd: Bool?
    /// The last telnet function received. Defaults to IAC.
    private var last = TelnetFunction.IAC
    /// A buffer storing longer received telnet sequences.
    private var buffer = Data()
    
    internal func isBegin(byte: UInt8) -> Bool {
        return byte == TelnetFunction.IAC.rawValue
    }
    
    internal func process(byte: UInt8, sender: ConnectionSender) -> Bool {
        print(byte)
        var result = false
        
        defer {
            if !result {
                hasEnd = nil
                buffer = Data()
                last   = .IAC
            }
        }
        
        if let hasEnd {
            if hasEnd {
                // Buffer until IAC SE, parse on receipt of it
                if byte == TelnetFunction.IAC.rawValue {
                    if last == .IAC {
                        buffer.append(byte)
                    } else {
                        last = .IAC
                    }
                    result = true
                } else if byte == TelnetFunction.SE.rawValue && last == TelnetFunction.IAC {
                    parseBuffer(data: buffer, sender: sender)
                } else {
                    buffer.append(byte)
                    result = true
                }
            } else {
                // Normal telnet option w/o parameters
                handleSingleOption(previous: last, byte: byte, sender: sender)
            }
        } else if let code = TelnetFunction(rawValue: byte) {
            switch code {
            case .WILL, .WONT, .DO, .DONT:
                hasEnd = false
                result = true
                
            case .SB:
                hasEnd = true
                result = true
                
            default:
                print("Error1")
            }
            last = code
        }
        return result
    }
    
    /// Parses the given telnet buffer.
    ///
    /// It should consist of the contents of an SB subnegotiation,
    /// but without the telnet control codes.
    ///
    /// - Parameter data: The actual buffer to be parsed.
    /// - Parameter sender: The sender used for sending the response.
    private func parseBuffer(data: Data, sender: ConnectionSender) {
        if let first = data.first, let code = Code(rawValue: first) {
            switch code {
            case .charset:
                guard data.count > 3 else { return }
                if data[1] == 1 {
                    let separator = data[2]
                    var sets: [String] = []
                    var buffer = ""
                    
                    for i in 3 ..< data.count {
                        if data[i] == separator {
                            sets.append(buffer)
                            buffer = ""
                        } else {
                            buffer.append(Character(Unicode.Scalar(data[i])))
                        }
                    }
                    
                    var firstMatch: String.Encoding?
                    var firstMatchString: String?
                    for set in sets {
                        switch set.lowercased() {
                        case "utf-8":  firstMatch = .utf8
                        case "utf-16": firstMatch = .utf16
                        case "ascii":  firstMatch = .ascii
                        // And maybe some more in the future...
                            
                        default: break
                        }
                        if firstMatch != nil {
                            firstMatchString = set
                            break
                        }
                    }
                    if let firstMatch {
                        var data = Data()
                        data.append(Code.charset.rawValue)
                        data.append(3)
                        data.append(firstMatchString!.data(using: .ascii)!)
                        sender.charset = firstMatch
                        sendSB(sender: sender, data: data)
                    } else {
                        sendSB(sender: sender, data: Code.charset.rawValue, 3)
                    }
                }
                
            default: break
            }
        }
    }
    
    /// This function handles a single telnet function.
    ///
    /// - Parameter previous: The previously received telnet option such as DO.
    /// - Parameter byte: The telnet function to handle.
    /// - Parameter sender: The sender used for sending back the response.
    private func handleSingleOption(previous: TelnetFunction, byte: UInt8, sender: ConnectionSender) {
        var refuse = false
        if let code = Code(rawValue: byte) {
            switch code {
            case .binary_transmission:
                switch previous {
                case .DO, .WILL:
                    // sender.escapeIAC = true
                    sendSingle(mode: previous == .DO ? .WILL : .DO, function: byte, sender: sender)
                    
                case .DONT, .WONT:
                    // sender.escapeIAC = false
                    sendSingle(mode: previous == .DONT ? .WONT : .DONT, function: byte, sender: sender)
                    
                default: refuse = true
                }
                
            case .charset:
                if previous == .WILL {
                    sendSingle(mode: .DO, function: byte, sender: sender)
                } else if previous == .DO {
                    sendSingle(mode: .WILL, function: byte, sender: sender)
                }
                
            default:
                refuse = true
            }
        }
        if (refuse) {
            sendSingle(mode: previous.opposite, function: byte, sender: sender)
        }
    }
    
    /// Sends back a single telnet function response.
    ///
    /// The sent message looks like: IAC `mode` `function`.
    ///
    /// - Parameter mode: The mode to sent to the remote host, such as `WILL`.
    /// - Parameter function: The code of the telnet function.
    /// - Parameter sender: The sender used for sending the response.
    private func sendSingle(mode: TelnetFunction, function: UInt8, sender: ConnectionSender) {
        var data = Data()
        
        data.append(TelnetFunction.IAC.rawValue)
        data.append(mode.rawValue)
        data.append(function)
        
        print("IAC \(mode) \(function)")
        
        sender.send(data: data)
    }
    
    private func sendSB(sender: ConnectionSender, data: Data) {
        var d = Data()
        
        d.append(TelnetFunction.IAC.rawValue)
        d.append(TelnetFunction.SB.rawValue)
        
        d.append(contentsOf: data)
        
        d.append(TelnetFunction.IAC.rawValue)
        d.append(TelnetFunction.SE.rawValue)
        
        sender.send(data: d)
    }
    
    /// Sends back the given sub negatiation.
    ///
    /// The sent message looks like: IAC SB `data` IAC SE.
    ///
    /// - Parameter sender: The sender used for sending the response.
    /// - Parameter data: The data to be sent as sub negotiation.
    private func sendSB(sender: ConnectionSender, data: UInt8...) {
        sendSB(sender: sender, data: Data(data))
    }
}
