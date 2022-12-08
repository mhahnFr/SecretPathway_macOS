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

import AppKit
import Network
import SwiftUI

/// This class controls a view that acts as  user interface for a MUD connection.
class ConnectionDelegate: NSObject, NSWindowDelegate, ObservableObject, ConnectionListener, TextViewBridgeDelegate {
    /// The default style to be used for user entered text.
    static let inputStyle  = SPStyle(foreground: .gray)
    /// The default style to be used for the prompt text.
    static let promptStyle = SPStyle()
    /// The length of the content text used as SwiftUI trigger.
    @Published private(set) var contentLength = 0
    /// The prompt text.
    @Published private(set) var prompt:  String?
    /// A string that can hold a message displayed for the user.
    @Published private(set) var message: String?
    /// The color to be used for the user message.
    @Published private(set) var messageColor: Color?
    
    /// Callback to be called when the window this instance is controlling is definitively closing.
    var onClose: ((ConnectionDelegate) -> Void)?
    
    /// The window that is controlled by this delegate instance.
    private(set) weak var window: NSWindow?
    
    /// The connection that is managed by this delegate instance.
    private var connection: Connection
    /// The attributed string that should be appended the next time the view is updated.
    private var appendix = NSMutableAttributedString()
    /// Indicates whether incoming data should be treated as ANSI escape code.
    private var wasAnsi = false
    /// Indicates whether incoming data should be treated as a SPP escape sequence.
    private var wasSPP = false
    /// The current escaped buffer.
    private var ansiBuffer = Data()
    /// The current SPP escape sequence.
    private var sppBuffer = Data()
    /// The style currently being used for incoming text.
    private var currentStyle = SPStyle()
    
    /// The last timer used to remove the user message. Nil if none is active.
    private weak var messageTimer: Timer?
    /// The last timer to used to retry to connect. Nil if none is active.
    private weak var retryTimer:   Timer?
    
    /// Initializes this instance using the given connection.
    ///
    /// - Parameter connection: The connection to be controlled by this instance.
    /// - Parameter window: The window optionally controlled by this instance.
    init(for connection: Connection, window: NSWindow? = nil) {
        self.connection = connection
        self.window     = window
        
        super.init()
        
        self.connection.connectionListener = self
        self.connection.start()
    }
    
    /// Creates a string from the given block of data.
    ///
    /// All non-ascii characters are removed from a copy of the block of data
    /// before creating the string from.
    ///
    /// - Parameter data: The data to filter and create a string from.
    /// - Returns: A string containing only ASCII characters built from the given piece of data.
    private func plainAscii(from data: Data) -> String {
        var filteredData = data
        
        for i in 0 ..< filteredData.endIndex {
            if filteredData[i] > 127 {
                filteredData[i] = Character("-").asciiValue!
            }
        }
        
        return String(data: filteredData, encoding: .ascii)!
    }
    
    internal func initTextView(_ textView: NSTextView) {
        textView.isEditable = false
        textView.font       = NSFont.monospacedSystemFont(ofSize: Settings.shared.fontSize, weight: .regular)
        textView.textColor  = .textColor
    }
    
    internal func updateTextView(_ textView: NSTextView) {
        textView.textStorage?.append(appendix)
        appendix = NSMutableAttributedString()
        if let font = textView.font {
            textView.font = NSFontManager.shared.convert(font, toSize: CGFloat(Settings.shared.fontSize))
        }
        textView.scrollToEndOfDocument(self)
    }
    
    /// Appends the given NSAttributedString to the content and triggers a SwiftUI update.
    ///
    /// The triggering of the SwiftUI update is done in the correct thread.
    ///
    /// - Parameter newContent: The new String to be appended.
    private func appendToContent(_ newContent: NSAttributedString) {
        DispatchQueue.main.async {
            self.appendix.append(newContent)
            self.contentLength += newContent.length
        }
    }
    
    /// Parses the given buffer into the current style.
    ///
    /// If it is impossible, false is returned and the current style remains the same as before
    /// invocation of this function.
    ///
    /// - Parameter buffer: The byte buffer to parse.
    /// - Returns: Whether the ANSI code was successfully parsed.
    private func parseANSIBuffer(_ buffer: Data) -> Bool {
        guard let string = String(data: buffer, encoding: .ascii) else { return false }
        
        let before = currentStyle
        
        let sub = string[string.index(after: string.startIndex)...]
        for split in sub.split(separator: ";", omittingEmptySubsequences: true) {
            if let decoded = Int(split) {
                switch decoded {
                case 0:  currentStyle            = SPStyle()
                case 1:  currentStyle.bold       = true
                case 3:  currentStyle.italic     = true
                case 4:  currentStyle.underlined = true
                case 21: currentStyle.bold       = false
                case 23: currentStyle.italic     = false
                case 24: currentStyle.underlined = false
                    
                // Foreground
                case 30: currentStyle.foreground = .black
                case 31: currentStyle.foreground = .red
                case 32: currentStyle.foreground = .green
                case 33: currentStyle.foreground = .yellow
                case 34: currentStyle.foreground = .blue
                case 35: currentStyle.foreground = .magenta
                case 36: currentStyle.foreground = .cyan
                case 37: currentStyle.foreground = .lightGray
                case 39: currentStyle.foreground = .textColor
                case 90: currentStyle.foreground = .darkGray
                case 97: currentStyle.foreground = .white
                    
                // Background
                case 40:  currentStyle.background = .black
                case 41:  currentStyle.background = .red
                case 42:  currentStyle.background = .green
                case 43:  currentStyle.background = .yellow
                case 44:  currentStyle.background = .blue
                case 45:  currentStyle.background = .magenta
                case 46:  currentStyle.background = .cyan
                case 47:  currentStyle.background = .lightGray
                case 49:  currentStyle.background = .textBackgroundColor
                case 100: currentStyle.background = .darkGray
                case 107: currentStyle.background = .white
                    
                // TODO: 256 bit colour, RGB colour...
                    
                default: print("Code not supported: \(decoded)!")
                }
            } else {
                currentStyle = before
                return false
            }
        }
        return true
    }
    
    /// Handles incoming data.
    ///
    /// - Parameter data: The new block of bytes
    internal func receive(data: Data) {
        var text      = Data()
        var ansiBegin = 0
        var bytes     = 0

        var closedStyles: [(begin: Int, style: SPStyle)] = []

        for byte in data {
            switch byte {
            case 0x1B:
                wasAnsi    = true
                ansiBuffer = Data()
                ansiBegin  = bytes
                
            case 0x6D where wasAnsi:
                wasAnsi = false
                
                let oldCurrentStyle = currentStyle
                if parseANSIBuffer(ansiBuffer) {
                    if ansiBegin != 0 && closedStyles.isEmpty {
                        closedStyles.append((0, oldCurrentStyle))
                    }
                    closedStyles.append((begin: ansiBegin, style: currentStyle))
                } else {
                    print("Error while parsing ANSI code!")
                }
                
            case SPProtocolConstants.BEGIN where !wasAnsi:
                wasSPP    = true
                sppBuffer = Data()
                
            case SPProtocolConstants.END where !wasAnsi && wasSPP:
                wasSPP = false
                
                // TODO: Parse SPP
                print("SPP buffer: \(sppBuffer)")
                
            default:
                if wasAnsi {
                    ansiBuffer.append(byte)
                } else if wasSPP {
                    sppBuffer.append(byte)
                } else {
                    text.append(byte)
                    bytes += 1
                }
            }
        }
        let styledString = NSMutableAttributedString(string: String(data: text, encoding: .utf8) ?? plainAscii(from: text))
        
        if closedStyles.isEmpty {
            styledString.setAttributes(currentStyle.native, range: NSMakeRange(0, styledString.length))
        } else {
            let factor = bytes > 0 ? (Double(styledString.length) / Double(bytes)) : 1
            for (i, style) in closedStyles.enumerated() {
                let len: Int
                if i + 1 < closedStyles.endIndex {
                    len = Int(Double((closedStyles[i + 1].begin - style.begin)) * factor)
                } else {
                    len = styledString.length - Int(Double(style.begin) * factor)
                }
                
                styledString.setAttributes(style.style.native, range: NSMakeRange(Int(Double(style.begin) * factor), len))
            }
        }
        appendToContent(styledString)
    }
    
    /// Handles connection errors.
    ///
    /// - Parameter error: The raised error.
    internal func handleError(_ error: ConnectionError) {
        guard !connection.isClosed else { return }
        
        #if DEBUG
        var tmpMessage: String
        #else
        let tmpMessage: String
        #endif
        
        switch error {
        case .generic(let error):
            tmpMessage = "General error!"
        #if DEBUG
            tmpMessage += " (\(error.localizedDescription))"
        #endif
            
        case .receiving(let error):
            tmpMessage = "Error while receiving data!"
        #if DEBUG
            tmpMessage += " (\(error.localizedDescription))"
        #endif
            
        case .sending(let error):
            tmpMessage = "Error while sending data!"
        #if DEBUG
            tmpMessage += " (\(error.localizedDescription))"
        #endif
            
        case .connecting(let error):
            tmpMessage = "Could not connect to \"\(connection.name)\"!"
        #if DEBUG
            tmpMessage += " (\(error.localizedDescription))"
        #endif
        }
        
        DispatchQueue.main.async { self.updateMessage(tmpMessage, color: .red) }
    }
    
    /// Displays a message according to the given state.
    ///
    /// - Parameter state: The state of the connection.
    internal func stateChanged(to state: NWConnection.State) {
        var tmpColor: Color?
        var timeout:  Int?
        
        var retry      = false
        var message    = true
        var tmpMessage = ""
        
        messageTimer?.invalidate()
        
        switch state {
        case .setup, .preparing:
            tmpMessage = "Connecting..."
            
        case .ready:
            tmpMessage = "Connected."
            tmpColor   = .green
            timeout    = 5
            
        case .cancelled:
            tmpMessage = "Disconnected!"
            tmpColor   = .yellow
            
        case .waiting(let error):
            retry = true
            fallthrough
        case .failed(let error):
            message = false
            handleError(.connecting(error: error))
            
        default:
            fatalError()
        }
        
        DispatchQueue.main.async {
            if message { self.updateMessage(tmpMessage, color: tmpColor) }
            if let timeout {
                self.messageTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { _ in
                    self.updateMessage(nil)
                    self.messageTimer = nil
                }
            }
            if !retry {
                self.retryTimer?.invalidate()
                self.retryTimer = nil
            } else {
                self.retryTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(2.5), repeats: true) { _ in
                    self.connection.retry()
                }
            }
        }
    }
    
    /// Updates the displayed message.
    ///
    /// This function has to be called in the mein DispatchQueue.
    ///
    /// - Parameter message: The new message to be displayed.
    /// - Parameter color: The color to be used to display the message.
    private func updateMessage(_ message: String?, color: Color? = nil) {
        withAnimation {
            self.message      = message
            self.messageColor = color
        }
    }
    
    /// Attempts to send the given string.
    ///
    /// - Parameter text: The text that should be sent.
    func send(_ text: String) {
        let toAppend = NSMutableAttributedString(string: text + "\n", attributes: ConnectionDelegate.inputStyle.native)
        
        if let prompt {
            let tmp = NSMutableAttributedString(string: prompt, attributes: ConnectionDelegate.promptStyle.native)
            
            if prompt.last != " " { tmp.append(NSAttributedString(string: " ")) }
            
            toAppend.insert(tmp, at: 0)
            
        }
        appendToContent(toAppend)
        
        let data = toAppend.string.data(using: .utf8, allowLossyConversion: true)!
        
        connection.send(data: data)
    }
    
    /// Closes the connection controlled by this delegate.
    func closeConnection() {
        connection.close()
        
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    /// Asks the user if he whishes to close the connection if it is active.
    ///
    /// Returns true if the connection has been or was already closed.
    ///
    /// - Returns: Whether the connection is closed.
    func maybeCloseConnection() -> Bool {
        var result = true
        
        if !connection.isClosed {
            result = Dialog(title: "\(Constants.APP_NAME): Active connection",
                             text: "The connection \"\(connection.name)\" is active.",
                         addition: "Do you want to close it?",
                     cancelButton: "Cancel")
                    .show()
            if result { closeConnection() }
        }
        return result
    }
    
    /// Attempts to reestablish the current connection.
    ///
    /// If a connection is active, the user is prompted whether he wishes to
    /// close the active connection.
    /// Does nothing if the user cancels the action.
    func maybeReconnect() {
        if maybeCloseConnection() {
            connection = Connection(from: connection)
            connection.connectionListener = self
            connection.start()
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        maybeCloseConnection()
    }
    
    func windowWillClose(_ notification: Notification) {
        if let onClose { onClose(self) }
    }
}
