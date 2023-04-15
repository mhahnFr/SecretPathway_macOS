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

/// This class acts as a delegate for the EditorView.
///
/// It features the LPC syntax highlighting.
class EditorDelegate: NSObject, TextViewBridgeDelegate, NSTextViewDelegate, ObservableObject {
    /// Indicates whether the syntax highlighting is enabled.
    @Published var syntaxHighlighting = Settings.shared.editorSyntaxHighlighting {
        didSet { toggleHighlighting() }
    }
    
    /// The closure called when the user clicks on the "Close" button.
    var onClose: (() -> Void)?
    /// The theme to be used for the syntax highlighting.
    var theme: SPTheme = restoreTheme()
    
    /// A reference to the text storage of the text view.
    private weak var textStorage: NSTextStorage!
    
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
    }
    
    internal func textDidChange(_ notification: Notification) {
        if syntaxHighlighting {
            highlight()
        }
    }
    
    /// Saves the text by sending a message to the server.
    func saveText() {
        // TODO: Save the text
        print("Saving")
    }
    
    /// Closes the editor.
    func close() {
        onClose?()
    }
    
    /// Toggles the highlighting.
    ///
    /// If the highlighting is enabled, the text is highlighted. Otherwise,
    /// the text color is reset to normal.
    private func toggleHighlighting() {
        if syntaxHighlighting {
            highlight()
        } else {
            textStorage.setAttributes(SPStyle().native, range: NSMakeRange(0, textStorage.length))
        }
    }
    
    /// Performs the highlighting of the text.
    private func highlight() {
        var tokenizer = Tokenizer(stream: StringStream(text: textStorage.string), commentTokens: true)
        var token = tokenizer.nextToken()
        while token.type != .EOF {            
            textStorage.setAttributes(theme.styleFor(tokenType: token.type).native, range: NSMakeRange(token.begin, token.end - token.begin))
            
            token = tokenizer.nextToken()
        }
    }
}
