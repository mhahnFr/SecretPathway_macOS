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

import AppKit
import Network
import SwiftUI

/// This class controls a view that acts as  user interface for a MUD connection.
class ConnectionDelegate: NSObject, NSWindowDelegate, ObservableObject, ConnectionListener, ConnectionSender, TextViewBridgeDelegate {
    /// The default style to be used for user entered text.
    static let inputStyle  = SPStyle(foreground: .gray)
    /// The default style to be used for the prompt text.
    static let promptStyle = SPStyle()
    /// The length of the content text used as SwiftUI trigger.
    @Published private(set) var contentLength = 0
    /// The prompt text.
    @Published private(set) var promptString: String?
    /// A string that can hold a message displayed for the user.
    @Published private(set) var message: String? {
        didSet {
            editorDelegate?.connectionStatus = message
            editors.forEach { $0.connectionStatus = message }
        }
    }
    /// The color to be used for the user message.
    @Published private(set) var messageColor: Color? {
        didSet {
            editorDelegate?.connectionColor = messageColor
            editors.forEach { $0.connectionColor = messageColor }
        }
    }
    /// The delegate to be used for the inlined LPC editor.
    @Published private(set) var editorDelegate: EditorDelegate?
    /// Indicates whether to show the password field.
    @Published private(set) var showPasswordField = false
    
    /// Indicates whether an inlined editor is being displayed.
    private(set) var isEditorShowing = false
    
    /// Callback to be called when the window this instance is controlling is definitively closing.
    var onClose: ((ConnectionDelegate) -> Void)?
    /// Indicates whether to use escaped IACs.
    var escapeIAC = false
    /// The charset to be used for sending and receiving text.
    var charset = Settings.shared.useUTF8 ? String.Encoding.utf8 : String.Encoding.ascii
    
    /// The window that is controlled by this delegate instance.
    private(set) weak var window: NSWindow?
    
    /// The SPP plugin.
    private lazy var sppPlugin = SPPPlugin(sender: self)
    /// The protocol abstractions object.
    private lazy var protocols = Protocols(sender: self, plugins: sppPlugin,
                                                                  TelnetPlugin(),
                                                                  ANSIPlugin(self))
    
    /// The connection that is managed by this delegate instance.
    private var connection: Connection
    /// The full received and styled text.
    private var fullText = NSMutableAttributedString()
    /// The attributed string that should be appended the next time the view is updated.
    private var appendix = NSMutableAttributedString()
    /// Indicates whether the text view has been initialized.
    private var inited = false
    /// Indicates whether incoming data should be passed to the special protocols.
    private var wasSpecial = false
    /// Indicates whether the last received byte was telnet's `IAC` function.
    private var lastWasIAC = false
    /// A buffer used for broken unicode points.
    private var unicodeBuffer = Data()
    /// The currently opened editors.
    private var editors: [EditorDelegate] = []
    /// The style currently being used for incoming text.
    internal var currentStyle = SPStyle()
    /// Indicated whether to hide user input.
    internal var passwordMode: Bool {
        set {
            DispatchQueue.main.async {
                self.showPasswordField = newValue
            }
        }
        get { showPasswordField }
    }
    internal var prompt: String? {
        set {
            DispatchQueue.main.async {
                self.promptString = newValue
            }
        }
        get { promptString }
    }
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
    
    private func resetBuffers() {
        escapeIAC     = false
        wasSpecial    = false
        lastWasIAC    = false
        unicodeBuffer = Data()
        charset       = Settings.shared.useUTF8 ? String.Encoding.utf8 : String.Encoding.ascii
        sppPlugin     = SPPPlugin(sender: self)
        protocols     = Protocols(sender: self, plugins: sppPlugin,
                                                         TelnetPlugin(),
                                                         ANSIPlugin(self))
        currentStyle  = SPStyle()
        passwordMode  = false
        prompt        = nil
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
        
        inited = true
    }
    
    internal func updateTextView(_ textView: NSTextView) {
        guard let backingStorage = textView.textStorage else { fatalError("NSTextView's textStorage should never be nil!") }
        
        if inited {
            inited = false
            backingStorage.append(fullText)
        } else {
            backingStorage.append(appendix)
        }
        
        appendix = NSMutableAttributedString()
        backingStorage.enumerateAttribute(.font, in: NSMakeRange(0, backingStorage.length)) { value, range, _ in
            guard let oldFont = value as? NSFont else { return }
            
            backingStorage.addAttribute(.font, value: oldFont.withSize(Settings.shared.fontSize), range: range)
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
            self.fullText.append(newContent)
            self.appendix.append(newContent)
            self.contentLength += newContent.length
        }
    }
    
    /// Shows an editor.
    ///
    /// - Parameter name: The name of the file to be displayed.
    /// - Parameter content: The content of the file to be displayed.
    func showEditor(file name: String? = nil, content: String? = nil) {
        let loader = sppPlugin.active ? SPPFileManager(plugin: sppPlugin)
                                      : LPCFileManager()
        if editorDelegate == nil && Settings.shared.editorInlined {
            showInlinedEditor(loader: loader, file: name, content: content)
        } else {
            openEditorWindow(loader: loader, file: name, content: content)
        }
    }
    
    /// Opens an editor window.
    ///
    /// - Parameters:
    ///   - loader: The loader used for resolving referenced files.
    ///   - name: The name of the file to be displayed.
    ///   - content: The content of the file to be displayed.
    private func openEditorWindow(loader: LPCFileManager, file name: String?, content: String?) {
        let settings = Settings.shared
        
        let window   = NSWindow(contentRect: NSMakeRect(CGFloat(settings.editorWindowX),
                                                        CGFloat(settings.editorWindowY),
                                                        CGFloat(settings.editorWidth),
                                                        CGFloat(settings.editorHeight)),
                                styleMask:   [.closable, .resizable, .titled, .miniaturizable],
                                backing:     .buffered,
                                defer:       false)
        let delegate = EditorDelegate(loader: loader, referrer: self, container: window, file: name, content: content)
        let content  = EditorView(delegate: delegate)
        delegate.onClose = {
            let bounds = window.frame
            settings.editorWindowX = Int(bounds.origin.x)
            settings.editorWindowY = Int(bounds.origin.y)
            settings.editorWidth   = Int(bounds.width)
            settings.editorHeight  = Int(bounds.height)
            
            window.performClose(delegate)
            self.editors.remove(at: self.editors.firstIndex(of: delegate)! )
        }
        window.contentView = NSHostingView(rootView: content)
        window.title       = "\(Constants.APP_NAME): Editor" + (name == nil ? "" : " - '\(name!)'")
        window.delegate    = delegate
        
        editors.append(delegate)
        
        window.makeKeyAndOrderFront(self)
    }
    
    /// Opens an inlined editor.
    ///
    /// - Parameters:
    ///   - loader: The loader to be used to resolve referenced files.
    ///   - name: The name of the opened file.
    ///   - content: The content of the file.
    private func showInlinedEditor(loader: LPCFileManager, file name: String?, content: String?) {
        isEditorShowing = true
        editorDelegate  = EditorDelegate(loader: loader, referrer: self, container: window, file: name, content: content)
        editorDelegate!.onClose = {
            self.editorDelegate  = nil
            self.isEditorShowing = false
        }
    }
    
    internal func enableSPP() {
        sppPlugin.active = true
    }
    
    internal func openEditor(file: String?, content: String?) {
        DispatchQueue.main.async {
            self.showEditor(file: file, content: content)
        }
    }
    
    /// Handles incoming data.
    ///
    /// - Parameter data: The new block of bytes
    internal func receive(data: Data) {
        var text      = unicodeBuffer
        var ansiBegin = 0
        var chars     = unicodeBuffer.count > 0 ? 1 : 0
        var oldStyle  = currentStyle
        
        unicodeBuffer = Data()
        
        var closedStyles: [(begin: Int, style: SPStyle)] = []

        for byte in data {
            if escapeIAC {
                if byte == 0xff {
                    if lastWasIAC {
                        lastWasIAC = false
                    } else {
                        lastWasIAC = true
                        continue
                    }
                } else if lastWasIAC {
                    lastWasIAC = false
                    wasSpecial = protocols.process(byte: 0xff)
                }
            }
            
            if wasSpecial {
                wasSpecial = protocols.process(byte: byte)
            } else {
                wasSpecial = protocols.process(byte: byte)
                
                if !wasSpecial {
                    text.append(byte)
                    if byte >> 7 == 0 || byte >> 6 == 3 {
                        chars += 1
                    }
                } else {
                    ansiBegin = chars
                }
            }
            if currentStyle != oldStyle {
                if ansiBegin != 0 && closedStyles.isEmpty {
                    closedStyles.append((0, oldStyle))
                }
                closedStyles.append((begin: ansiBegin, style: currentStyle))
                oldStyle = currentStyle
            }

        }
        
        if let last = text.last, last >> 7 == 1 {
            if last >> 6 == 2 {
                let exCount = text.count
                
                var index = text.count - 2
                while text[index] >> 7 == 1 && text[index] >> 6 == 2 {
                    index -= 1
                }
                
                let shifted = text[index] >> 4
                
                let oneCount = shifted == 0b1100 ? 2
                             : (shifted == 0b1110 ? 3 : 4)
                
                if text.count - index < oneCount {
                    for _ in index ..< exCount {
                        unicodeBuffer.append(text.remove(at: index))
                    }
                    chars -= 1
                }
            } else {
                unicodeBuffer.append(text.removeLast())
                chars -= 1
            }
        }
        
        let string = String(data: text, encoding: charset) ?? plainAscii(from: text)
        let styledString = NSMutableAttributedString(string: string)
        
        if closedStyles.isEmpty {
            styledString.setAttributes(currentStyle.native, range: NSMakeRange(0, styledString.length))
        } else {
            for (i, style) in closedStyles.enumerated() {
                let len: Int
                if i + 1 < closedStyles.endIndex {
                    len = closedStyles[i + 1].begin - style.begin
                } else {
                    len = string.count - style.begin
                }
                
                guard style.begin < string.count else { break }
                
                let begin = string.index(string.startIndex, offsetBy: style.begin)
                let end   = string.index(string.startIndex, offsetBy: style.begin + len)
                
                styledString.setAttributes(style.style.native, range: NSRange(begin ..< end, in: string))
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
        
        var available  = false
        var retry      = false
        var message    = true
        var tmpMessage = ""
        
        messageTimer?.invalidate()
        
        switch state {
        case .setup, .preparing:
            tmpMessage = "Connecting..."
            available  = true
            
        case .ready:
            tmpMessage = "Connected."
            tmpColor   = .green
            timeout    = 5
            available  = true
            
        case .cancelled:
            tmpMessage = "Disconnected!"
            tmpColor   = .yellow
            
        case .waiting(let error):
            retry     = true
            available = true
            fallthrough
        case .failed(let error):
            message = false
            handleError(.connecting(error: error))
            
        default:
            fatalError()
        }
        
        protocols.connectionAvailable = available
        
        DispatchQueue.main.async {
            if !available {
                self.passwordMode = false
                self.prompt       = nil
            }
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
        let toSend   = text + "\n"
        let toAppend = NSMutableAttributedString(string: passwordMode ? String(repeating: "*", count: text.count) : toSend, attributes: ConnectionDelegate.inputStyle.native)
        
        if let prompt {
            let tmp = NSMutableAttributedString(string: prompt, attributes: ConnectionDelegate.promptStyle.native)
            
            if prompt.last != " " { tmp.append(NSAttributedString(string: " ")) }
            
            toAppend.insert(tmp, at: 0)
            
        }
        appendToContent(toAppend)
        
        send(data: toSend.data(using: charset, allowLossyConversion: true)!)
    }

    internal func send(data: Data) {
        connection.send(data: data)
    }
    
    /// Closes the connection controlled by this delegate.
    func closeConnection() {
        connection.close()
        resetBuffers()
        
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    /// Asks the user if he whishes to close the connection if it is active.
    ///
    /// Returns true if the connection has been or was already closed.
    ///
    /// - Returns: Whether the connection is closed.
    func maybeCloseConnection() -> Bool {
        guard !connection.isClosed else { return true }
        
        let alert = NSAlert()
        
        alert.window.title    = "\(Constants.APP_NAME): Active connection"
        alert.messageText     = "The connection \"\(connection.name)\" is active."
        alert.informativeText = "Do you want to close it?"
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if !(editorDelegate?.close() ?? true) { return false }
            for editor in editors {
                if !editor.close() {
                    return false
                }
            }
            closeConnection()
            return true
        }
        return false
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
        onClose?(self)
    }
}
