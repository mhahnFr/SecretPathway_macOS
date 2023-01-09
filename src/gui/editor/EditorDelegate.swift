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
 * You should have received a copy of the GNU General Public License
 * along with this program, see the file LICENSE.
 * If not, see <https://www.gnu.org/licenses/>.
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
    
    /// A reference to the text storage of the text view.
    private weak var textStorage: NSTextStorage!
    
    internal func updateTextView(_ textView: NSTextView) {}
    
    internal func initTextView(_ textView: NSTextView) {
        textView.font      = NSFont.monospacedSystemFont(ofSize: Settings.shared.fontSize, weight: .regular)
        textView.textColor = .textColor
        textView.delegate  = self
        
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
        // TODO: Close the editor
        print("Closing")
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
        while token.type != .eof {
            let style: SPStyle
            
            switch token.type {
            case .identifier:
                style = SPStyle(foreground: .green)
                
            case .commentLine, .commentBlock:
                style = SPStyle(italic: true, foreground: .gray)
                
            case .string:
                style = SPStyle(foreground: .red)
                
            case .include, .inherit, .private, .protected, .public, .override, .deprecated, .new, .this, .nil, .true, .false, .sizeof, .is, .class, .void, .charKeyword, .intKeyword, .bool, .object, .stringKeyword, .symbolKeyword, .mapping, .any, .mixed, .auto, .operator, .let, .if, .else, .while, .do, .for, .foreach, .switch, .`case`, .`default`, .break, .continue, .return, .try, .catch:
                style = SPStyle(bold: true, foreground: .orange)
                
            default:
                style = SPStyle()
            }
            
            textStorage.setAttributes(style.native, range: NSMakeRange(token.begin, token.end - token.begin))
            
            token = tokenizer.nextToken()
        }
    }
}
