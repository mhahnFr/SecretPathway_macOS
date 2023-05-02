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
    @Published var connectionStatus: String?
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
    
    /// A reference to the text storage of the text view.
    private weak var textStorage: NSTextStorage!
    /// A reference to the actual text view.
    private weak var view: NSTextView!
    private weak var referrer: ConnectionDelegate!
    
    /// The highlights in the text.
    private var highlights: [Highlight] = []
    private var file: String?

    /// Initializes this delegate using the given file loader.
    ///
    /// - Parameter loader: The loader used for loading files.
    init(loader: LPCFileManager, referrer: ConnectionDelegate?, file name: String? = nil) {
        self.loader   = loader
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
        
        if let file {
            Task {
                await self.textStorage.append(NSAttributedString(string: loader.load(file: file) ?? ""))
                if self.syntaxHighlighting {
                    self.highlight()
                } else {
                    self.resetHighlight()
                }
            }
        }
    }
    
    internal func textDidChange(_ notification: Notification) {
        if syntaxHighlighting {
            highlight()
        }
    }
    
    internal func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }
    
    /// Updates the status text for the given cursor location.
    ///
    /// - Parameter location: The location for which to retrieve the status text.
    private func updateStatus() {
        guard let range = view.selectedRanges.first as? NSRange else { return }
        
        let location = range.location
        
        var set = false
        
        for highlight in highlights {
            if location >= highlight.begin && location <= highlight.end,
                let highlight = highlight as? MessagedHighlight {
                setStatus(text: highlight.message)
                set = true
            }
        }
        if !set { setStatus(text: "") }
    }
    
    private func setStatus(text: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.statusText = text
            }
        }
    }
    
    func openEditor() {
        referrer.showEditor()
    }
    
    /// Saves the text by sending a message to the server.
    func saveText() {
        // TODO: Save the text
        print("Saving")
    }
    
    /// Closes the editor.
    func close() -> Bool {
        // TODO: Check for unsaved changes etc...
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
            let context     = await interpreter.createContext(for: ast)
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