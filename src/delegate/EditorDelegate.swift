/*
 * SecretPathway_macOS - A MUD client, for macOS.
 *
 * Copyright (C) 2023  mhahnFr
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
import SwiftUI

/// This class acts as a delegate for the EditorView.
///
/// It features the LPC syntax highlighting.
class EditorDelegate: NSObject, TextViewBridgeDelegate, NSTextViewDelegate, NSWindowDelegate, ObservableObject {
    /// Indicates whether the syntax highlighting is enabled.
    @Published var syntaxHighlighting = Settings.shared.editorSyntaxHighlighting {
        didSet { toggleHighlighting() }
    }
    /// The status text of the underlying connection.
    @Published var connectionStatus: String?
    /// The color used for the connection status text.
    @Published var connectionColor: Color?
    /// The status text to be displayed beneath the text.
    @Published private(set) var statusText = ""
    
    /// The closure called when the user clicks on the "Close" button.
    var onClose: (() -> Void)?
    /// The theme to be used for the syntax highlighting.
    var theme = restoreTheme()
    /// Indicates whether the underlying file manager supports file compilation.
    var canCompile: Bool {
        loader.canCompile()
    }
    
    /// The loader used for fetching files.
    private let loader: LPCFileManager
    /// The delegate for the text storage.
    private let storageDelegate = SyntaxDocumentDelegate()

    /// A reference to the text storage of the text view.
    private weak var textStorage: NSTextStorage!
    /// A reference to the actual text view.
    private weak var view: NSTextView!
    /// The referrer that opened this editor instance.
    private weak var referrer: ConnectionDelegate!
    /// The window this editor is in.
    private weak var window: NSWindow!

    /// The highlights in the text.
    private var highlights: [Highlight] = []
    /// The associated file name.
    private var file: String?
    /// The lastly saved content.
    private var lastSaved = ""

    /// Initializes this delegate using the given file loader.
    ///
    /// - Parameter loader: The loader used for loading files.
    init(loader: LPCFileManager, referrer: ConnectionDelegate?, container window: NSWindow?, file name: String? = nil) {
        self.loader   = loader
        self.window   = window
        self.referrer = referrer
        self.file     = name
    }
    
    /// Attempts to restore the theme used for the editor.
    ///
    /// - Returns: Either the theme used previously or a default theme.
    private static func restoreTheme() -> SPTheme {
        if let url  = Settings.shared.editorTheme,
           let data = try? Data(contentsOf: url) {
            return (try? JSONDecoder().decode(JSONTheme.self, from: data)) ?? DefaultTheme()
        }
        return DefaultTheme()
    }
    
    internal func updateTextView(_ textView: NSTextView) {}
    
    internal func initTextView(_ textView: NSTextView) {
        textView.font        = NSFont.monospacedSystemFont(ofSize: Settings.shared.fontSize, weight: .regular)
        textView.textColor   = .textColor
        textView.delegate    = self
        textView.allowsUndo  = true
        textView.usesFindBar = true
        
        textView.isAutomaticQuoteSubstitutionEnabled  = false
        textView.isAutomaticDataDetectionEnabled      = false
        textView.isAutomaticLinkDetectionEnabled      = false
        textView.isAutomaticTextCompletionEnabled     = false
        textView.isAutomaticTextReplacementEnabled    = false
        textView.isAutomaticDashSubstitutionEnabled   = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        textStorage = textView.textStorage
        view        = textView
        textStorage.delegate = storageDelegate
        
        if let file {
            Task {
                self.setStatus(text: "Loading \"\(file)\"...")
                let appendix: String
                if let loaded = await loader.load(file: file) {
                    self.textStorage.append(NSAttributedString(string: loaded))
                    lastSaved = loaded
                    if self.syntaxHighlighting {
                        self.highlight()
                    } else {
                        self.resetHighlight()
                    }
                    appendix = "Done."
                } else {
                    appendix = "Failed!"
                }
                self.setStatus(text: "Loading \"\(file)\"... \(appendix)")
            }
        }
    }
    
    
    
    internal func textDidChange(_ notification: Notification) {
        print("is: \(view.selectedRange().location), delta: \(storageDelegate.delta)")
        if storageDelegate.delta != 0 {
            view.setSelectedRange(NSMakeRange(view.selectedRange().location + storageDelegate.delta, 0))
        }
        window.isDocumentEdited = textStorage.string != lastSaved
        if syntaxHighlighting {
            highlight()
        }
    }
    
    internal func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }
    
    internal func textView(_ textView: NSTextView, willDisplayToolTip tooltip: String, forCharacterAt characterIndex: Int) -> String? {
        getStatusText(for: characterIndex)
    }
    
    /// Returns the status text available for the given position.
    ///
    /// If no status text is available, `nil` is returned.
    ///
    /// - Parameter position: The position for which to query the message.
    /// - Returns: The available message or `nil`.
    private func getStatusText(for position: Int) -> String? {
        var toReturn = String?.none
        
        for highlight in highlights {
            if position >= highlight.begin && position <= highlight.end,
                let highlight = highlight as? MessagedHighlight {
                toReturn = highlight.message
            }
        }
        
        return toReturn
    }
    
    /// Updates the status text for the given cursor location.
    ///
    /// - Parameter location: The location for which to retrieve the status text.
    private func updateStatus() {
        guard let range = view.selectedRanges.first as? NSRange else { return }
        
        let location = range.location

        setStatus(text: getStatusText(for: location) ?? "")
    }
    
    /// Sets the status text.
    ///
    /// Takes care of using the correct thread.
    ///
    /// - Parameter text: The new text to be displayed.
    private func setStatus(text: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.statusText = text
            }
        }
    }
    
    /// Opens a new editor instance.
    func openEditor() {
        referrer.showEditor()
    }
    
    /// Saves the text by sending a message to the server.
    func saveText() {
        if file == nil {
            let alert = NSAlert()
            let field = NSTextField(frame: NSMakeRect(0, 0, alert.window.frame.width - 20, 24))
            
            alert.messageText                  = "File unnamed."
            alert.informativeText              = "Enter a name:"
            alert.accessoryView                = field
            alert.alertStyle                   = .informational
            alert.window.initialFirstResponder = field

            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            guard alert.runModal() == .alertFirstButtonReturn &&
                    !field.stringValue.isEmpty else { return }
            
            file = field.stringValue
        }
        let content = textStorage.string
        loader.save(file: file!, content: content)
        lastSaved = content
        window.isDocumentEdited = false
    }
    
    /// Closes the editor.
    func close() -> Bool {
        if window.isDocumentEdited {
            let alert = NSAlert()
            
            alert.alertStyle      = .warning
            alert.messageText     = "Do you want to save the changes?"
            alert.informativeText = "Unsaved changes are discarded otherwise."
            
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                saveText()
                return close()
                                           
            case .alertSecondButtonReturn: break
                
            default: return false
            }
        }
        onClose?()
        return true
    }
    
    /// Attempts to compile the text.
    func compile() {
        guard loader.canCompile() else { return }
        
        saveText()
        guard let file else { return }
        loader.compile(file: file)
    }
    
    /// Toggles the highlighting.
    ///
    /// If the highlighting is enabled, the text is highlighted. Otherwise,
    /// the text color is reset to normal.
    private func toggleHighlighting() {
        if syntaxHighlighting {
            highlight()
        } else {
            resetHighlight()
        }
    }
    
    /// Clears the visible syntax highlighting.
    private func resetHighlight() {
        textStorage.setAttributes(SPStyle().native, range: NSMakeRange(0, textStorage.length))
    }
    
    /// Performs the highlighting of the text.
    private func highlight() {
        textStorage.setAttributes(SPStyle().native, range: NSRange(0 ..< textStorage.length)) // TODO: Flickering
        var tokenizer = Tokenizer(stream: StringStream(text: textStorage.string), commentTokens: true)
        
        var comments: [Token] = []
        
        var token = tokenizer.nextToken()
        while token.type != .EOF {            
            textStorage.setAttributes((theme.styleFor(type: token.type) ?? SPStyle()).native, range: NSMakeRange(token.begin, token.end - token.begin))
            
            if token.isType(.COMMENT_LINE, .COMMENT_BLOCK) {
                comments.append(token)
            }
            
            token = tokenizer.nextToken()
        }
        let roTokens = comments
        Task(priority: .background) {
            let interpreter = Interpreter(loader: loader)
            var parser      = Parser(text: textStorage.string)
            let ast         = parser.parse()
            let context     = await interpreter.createContext(for: ast, file: self.file)
            self.highlights = interpreter.highlights
            
            DispatchQueue.main.async {
                for range in self.highlights {
                    if let style = self.theme.styleFor(type: range.type) {
                        self.textStorage.addAttributes(style.native, range: NSMakeRange(range.begin, range.end - range.begin))
                    }
                }
                for token in roTokens {
                    self.textStorage.setAttributes((self.theme.styleFor(type: token.type) ?? SPStyle()).native, range: NSMakeRange(token.begin, token.end - token.begin))
                }
                self.updateStatus()
            }
        }
    }
}
