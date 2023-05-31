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
class EditorDelegate: NSObject, TextViewBridgeDelegate, NSTextStorageDelegate, NSTextViewDelegate, NSWindowDelegate, ObservableObject, SuggestionShower {
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

    /// A reference to the text storage of the text view.
    private weak var textStorage: NSTextStorage!
    /// A reference to the actual text view.
    private weak var view: NSTextView!
    /// The referrer that opened this editor instance.
    private weak var referrer: ConnectionDelegate!
    /// The window this editor is in.
    private weak var window: NSWindow?

    /// The highlights in the text.
    private var highlights: [Highlight] = []
    /// The associated file name.
    private var file: String?
    /// The lastly saved content.
    private var lastSaved: String?
    /// The delta by which the cursor should be moved automatically.
    private var delta = 0
    /// The string that should be ignored on insertion.
    private var ignore: (Int, String)?
    private var beginSuggestions = false
    private var beginDotSuggestions = false
    private var beginSuperSuggestions = false
    private var updateSuggestions = false
    private var endSuggestions = true
    /// The tokens lastly recognized in the text.
    private var tokens = [Token]()
    /// The AST lastly parsed.
    private var ast = [ASTExpression]()
    /// The lastly generated interpretation context.
    private var context = Context()
    private var visitor = SuggestionVisitor()
    private var interpreterTimer: Timer?
    private var editedRange: (Int, Int)?
    private let box = NSBox()
    private var suggestionDelegate = SuggestionsDelegate(suggestions: [])
    private var suggestionWindow = NSWindow(contentRect: NSMakeRect(0, 0, 100, 100),
                                            styleMask:   [.fullSizeContentView, .borderless],
                                            backing:     .buffered,
                                            defer:       false)

    /// Initializes this delegate using the given file loader.
    ///
    /// - Parameter loader: The loader used for loading files.
    /// - Parameter referrer: The referring connection delegate.
    /// - Parameter window: The window this editor is contained in.
    /// - Parameter name: The name of the file.
    /// - Parameter content: The content of the file.
    init(loader: LPCFileManager, referrer: ConnectionDelegate?, container window: NSWindow?, file name: String? = nil, content: String? = nil) {
        self.loader    = loader
        self.window    = window
        self.referrer  = referrer
        self.file      = name
        self.lastSaved = content
        
        super.init()
        
        self.suggestionWindow.isReleasedWhenClosed                               = false
        self.suggestionWindow.titlebarAppearsTransparent                         = true
        self.suggestionWindow.titleVisibility                                    = .hidden
        self.suggestionWindow.standardWindowButton(.closeButton)?.isHidden       = true
        self.suggestionWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.suggestionWindow.standardWindowButton(.zoomButton)?.isHidden        = true
        self.suggestionWindow.isOpaque                                           = false
        self.suggestionWindow.backgroundColor                                    = .clear
        
        self.box.titlePosition       = .noTitle
        self.box.boxType             = .custom
        self.box.cornerRadius        = 5
        self.box.fillColor           = .windowBackgroundColor
        self.box.borderColor         = .controlColor
        self.box.autoresizesSubviews = true
        self.box.contentView         = NSHostingView(rootView: SuggestionsView(delegate: suggestionDelegate))
        
        
        self.suggestionWindow.contentView = self.box
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
        textStorage.delegate = self
        
        if let lastSaved {
            textStorage.append(NSAttributedString(string: lastSaved))
            if syntaxHighlighting {
                highlight()
            } else {
                resetHighlight()
            }
        }
    }
    
    internal func textDidChange(_ notification: Notification) {
        if delta != 0 {
            view.setSelectedRange(NSMakeRange(view.selectedRange().location + delta, 0))
        }
        window?.isDocumentEdited = textStorage.string != lastSaved
        if syntaxHighlighting {
            if updateSuggestions          { suggestionsUpdate()                   }
            if beginSuggestions           { computeSuggestionContext(position: view.selectedRange().location + delta,
                                                                     begin: true) }
            else if beginSuperSuggestions { startSuperSuggestions()               }
            else if beginDotSuggestions   { startDotSuggestions()                 }
            else if endSuggestions        { stopSuggestions()                     }
            highlight(range: editedRange ?? (0, 0))
        } else {
            resetHighlight()
        }
    }
    
    internal func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }
    
    internal func textView(_ textView: NSTextView, willDisplayToolTip tooltip: String, forCharacterAt characterIndex: Int) -> String? {
        getStatusText(for: characterIndex)
    }
    
    internal func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        
        let tmp = (editedRange.location, delta)
        if self.editedRange != nil {
            self.editedRange!.1 += tmp.1
        } else {
            self.editedRange = tmp
        }
        
        let underlying = textStorage.string
        if editedRange.length == 0 {
            if isInWord(underlying, editedRange.location) {
                updateSuggestionsImpl(type: nil, returnType: nil)
            } else {
                stopSuggestions()
            }
            return
        }
        
        let str = textStorage.attributedSubstring(from: editedRange).string
        
        if let ignore,
           editedRange.location == ignore.0,
           str == ignore.1 {
            textStorage.replaceCharacters(in: editedRange, with: "")
            self.delta = 1
            return
        } else {
            self.ignore = nil
        }
        beginSuggestions      = false
        beginDotSuggestions   = false
        beginSuperSuggestions = false
        updateSuggestions     = false
        endSuggestions        = true
        
        switch str {
        case "\t":
            textStorage.replaceCharacters(in: editedRange, with: "    ")
            self.delta = 0
            
        case "(", "{", "[", "\"", "'":
            if isSpecial(underlying, editedRange.location + editedRange.length) {
                let closing = getClosingString(str)
                textStorage.insert(NSAttributedString(string: closing), at: editedRange.location + editedRange.length)
                self.ignore = (editedRange.location + editedRange.length, closing)
                self.delta = -1
            } else {
                self.delta = 0
            }
            
        case "!" where editedRange.location >= 2 &&
                       underlying[underlying.index(underlying.startIndex, offsetBy: editedRange.location - 2) ..<
                                  underlying.index(underlying.startIndex, offsetBy: editedRange.location)] == "/*" &&
                       isWhitespace(underlying, editedRange.location + editedRange.length):
            textStorage.insert(NSAttributedString(string: "!*/"), at: editedRange.location + editedRange.length)
            self.delta = -3
            
        case "}" where isOnlyWhitespacesOnLine(underlying, editedRange.location):
            let lineBegin = getLineBegin(underlying, editedRange.location)
            let len = min(editedRange.location - lineBegin, 4)
            textStorage.replaceCharacters(in: NSMakeRange(editedRange.location - len, len), with: "")
            self.delta = 0
            
        case ":" where isColon(underlying, editedRange.location - 1):
            beginSuperSuggestions = true
            self.delta            = 0
            
        case "." where isInWord(underlying, editedRange.location - 1):
            beginDotSuggestions = true
            self.delta          = 0
            
        case ">" where isDash(underlying, editedRange.location - 1):
            beginDotSuggestions = true
            self.delta          = 0
            
        case "\n":
            let openingParenthesis = isPreviousOpeningParenthesis(underlying, editedRange.location)
            if openingParenthesis && isClosingParenthesis(underlying, editedRange.location + editedRange.length) {
                let indent = String(repeating: " ", count: getPreviousIndent(underlying, editedRange.location))
                textStorage.insert(NSAttributedString(string: indent + "    \n" + indent), at: editedRange.location + editedRange.length)
                self.delta = -indent.count - 1
            } else {
                textStorage.insert(NSAttributedString(string: String(repeating: " ", count: getPreviousIndent(underlying, editedRange.location)) +
                                                                                            (openingParenthesis ? "    " : "")),
                                   at: editedRange.location + editedRange.length)
                self.delta = 0
            }
            
        default:
            if str.count == 1,
               !Tokenizer.isSpecial(str[str.startIndex]),
               !str[str.startIndex].isNumber {
                if isSpecial(underlying, editedRange.location - 1),
                   isSpecial(underlying, editedRange.location + editedRange.length) {
                    beginSuggestions = !isInToken(position: editedRange.location, .STRING,
                                                                                  .CHARACTER,
                                                                                  .COMMENT_BLOCK,
                                                                                  .COMMENT_LINE)
                }
                updateSuggestions = true
                endSuggestions    = false
            }
            self.delta = 0
        }
    }
    
    internal func toggleSuggestions() {
        if suggestionWindow.isVisible {
            startTimer()
            suggestionWindow.orderOut(self)
        } else {
            let frame = view.firstRect(forCharacterRange: NSMakeRange(updateSuggestionsImpl(type: nil, returnType: nil), 0),
                                       actualRange:       nil)
            suggestionWindow.setContentSize(NSSize(width: 300, height: 250)) // TODO: Sizing
            suggestionWindow.setFrameOrigin(NSPoint(x: frame.origin.x - 5,
                                                    y: frame.origin.y - frame.height - box.frame.height))
            suggestionWindow.orderFront(self)
        }
    }
    
    private func computeSuggestionContext(position: Int, begin: Bool) {
        Task {
            visit(position: position)
            DispatchQueue.main.async {
                let type = self.visitor.suggestionType
                
                if begin && type != .literal {
                    self.startSuggestions()
                } else if type == .literal {
                    self.stopSuggestions()
                } else {
                    self.updateSuggestionContext(type: type, returnType: self.visitor.expectedType)
                }
            }
        }
    }
    
    private func startSuggestions() {
        if !suggestionWindow.isVisible {
            toggleSuggestions()
        }
    }
    
    private func startSuperSuggestions() {
        // TODO: Implement
    }
    
    private func startDotSuggestions() {
        // TODO: Implement
    }
    
    private func suggestionsUpdate() {
        updateSuggestionsImpl(type: nil, returnType: nil)
    }
    
    private func stopSuggestions() {
        if suggestionWindow.isVisible {
            toggleSuggestions()
        }
    }
    
    private func updateSuggestionContext(type: SuggestionType, returnType: TypeProto?) {
        updateSuggestionsImpl(type: type, returnType: returnType)
    }
    
    private func getWordBegin(_ text: String, _ position: Int) -> Int {
        var begin = position - 1
        while begin > 0 && !Tokenizer.isSpecial(text[text.index(text.startIndex, offsetBy: begin)]) { begin -= 1 }
        if begin < 0 || Tokenizer.isSpecial(text[text.index(text.startIndex, offsetBy: begin)]) { begin += 1 }
        return begin
    }
    
    @discardableResult
    private func updateSuggestionsImpl(type: SuggestionType?, returnType: TypeProto?) -> Int {
        let caretPosition = view.selectedRange().location
        
        if type == nil && returnType == nil { computeSuggestionContext(position: caretPosition, begin: false) }
        
        // TODO: context switches
        var suggestions = context.createSuggestions(at: caretPosition, with: type ?? .any)
        // TODO: Sort by expected type
        let text = textStorage.string
        let toReturn: Int
        if isInWord(text, caretPosition) {
            let begin = getWordBegin(text, caretPosition)
            toReturn  = begin
            let wordBegin = text[text.index(text.startIndex, offsetBy: begin) ..< text.index(text.startIndex, offsetBy: caretPosition)]
            suggestions.removeAll(where: { $0.suggestion.isEmpty || !$0.description.contains(wordBegin) })
            suggestions.sort {
                var aa = $0.description.hasPrefix(wordBegin)
                var bb = $1.description.hasPrefix(wordBegin)
                
                if !aa && !bb {
                    aa = $0.description.contains(wordBegin)
                    bb = $0.description.contains(wordBegin)
                }
                if aa == bb { return false }
                return aa
            }
        } else {
            toReturn = caretPosition
        }
        suggestionDelegate.suggestions = suggestions
        return toReturn
    }
    
    private func visit(position: Int) {
        for node in ast {
            if position >= node.begin && position <= node.end {
                visitor.visit(node: node, position: position, context: context)
                return
            }
        }
        guard let last = ast.last else { return }
        visitor.visit(node: last, position: position, context: context)
    }
    
    /// Returns whether the character at the given position is a `-`.
    ///
    /// If the given position is out of range, `false` is returned.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - position: The position of the character to be checked.
    /// - Returns: Whether the character in the given string at the given position is a dash.
    private func isDash(_ string: String, _ position: Int) -> Bool {
        guard position > 0 && position < string.count else { return false }
        
        return string[string.index(string.startIndex, offsetBy: position)] == "-"
    }
    
    /// Returns whether the given position is in a token of the given type.
    ///
    /// - Parameters:
    ///   - position: The position to be checked.
    ///   - types: The token types to be taken into account.
    /// - Returns: Whether the given position is in a token of the given type.
    private func isInToken(position: Int, _ types: TokenType...) -> Bool {
        for token in tokens {
            if types.contains(token.type),
               position < token.end,
               position > token.begin {
                return true
            }
        }
        
        return false
    }
    
    /// Returns whether the character at the given position is a `:`.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - offset: The position.
    /// - Returns: Whether the character at the given position is a colon.
    private func isColon(_ string: String, _ offset: Int) -> Bool {
        guard offset >= 0 && offset <= string.count else { return false }
        
        return string[string.index(string.startIndex, offsetBy: offset)] == ":"
    }
    
    /// Returns whether the given position is in a word.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - offset: The position to be checked.
    /// - Returns: Whether the position is inside of a word.
    private func isInWord(_ string: String, _ offset: Int) -> Bool {
        (offset > 0 && offset - 1 < string.count && !Tokenizer.isSpecial(string[string.index(string.startIndex, offsetBy: offset - 1)])) ||
        (offset < string.count && offset >= 0 && !Tokenizer.isSpecial(string[string.index(string.startIndex, offsetBy: offset)]))
    }
    
    /// Returns the indentation level prior to the given position.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - offset: The position to be checked.
    /// - Returns: The indentation level prior to the given position.
    private func getPreviousIndent(_ string: String, _ offset: Int) -> Int {
        var lineBegin = getLineBegin(string, offset)
        var indent = 0
        while lineBegin < offset && string[string.index(string.startIndex, offsetBy: lineBegin)] == " " {
            lineBegin += 1
            indent    += 1
        }
        return indent
    }
    
    /// Returns whether the character prior to the given position is an opening parenthesis.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - offset: The position to be checked.
    /// - Returns: Whether the preceding character is an opening parenthesis.
    private func isPreviousOpeningParenthesis(_ string: String, _ offset: Int) -> Bool {
        guard offset > 0 else { return false }
        
        let c = string[string.index(string.startIndex, offsetBy: offset - 1)]
        return c == "(" ||
               c == "{" ||
               c == "["
    }
    
    /// Returns whether the character at the given position is a closing parenthesis.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - offset: The position to be checked.
    /// - Returns: Whether the following character is a closing parenthesis.
    private func isClosingParenthesis(_ string: String, _ offset: Int) -> Bool {
        guard offset < string.count else { return false }
        
        let c = string[string.index(string.startIndex, offsetBy: offset)]
        return c == ")" ||
               c == "}" ||
               c == "]"
    }
    
    /// Returns whether only spaces preceed the given position in the given string.
    ///
    /// - Parameters:
    ///   - line: The line in which to check.
    ///   - index: The position to be checked.
    /// - Returns: Whether only spaces preceed the position.
    private func isOnlyWhitespacesOnLine(_ line: String, _ index: Int) -> Bool {
        let lineBegin = getLineBegin(line, index)
        return isSpaces(String(line[line.index(line.startIndex, offsetBy: lineBegin) ..< line.index(line.startIndex, offsetBy: index)]))
    }
    
    /// Returns whether the given string contains only spaces (not whitespaces).
    ///
    /// - Parameter string: The string to be checked.
    /// - Returns: Whether string consists of only spaces.
    private func isSpaces(_ string: String) -> Bool {
        for c in string.unicodeScalars {
            guard c == " " else { return false }
        }
        return true
    }
    
    /// Returns the line begin of the line in which the given position is in.
    ///
    /// - Parameters:
    ///   - line: The line string to be checked.
    ///   - index: The position in the line.
    /// - Returns: The beginning position of the line.
    private func getLineBegin(_ line: String, _ index: Int) -> Int {
        var lineBegin = index > 0 ? index - 1 : 0
        while lineBegin > 0 && !line[line.index(line.startIndex, offsetBy: lineBegin)].isNewline {
            lineBegin -= 1
        }
        return lineBegin > 0 ? lineBegin + 1 : 0
    }
    
    /// Returns whether the following character is a whitespace.
    ///
    /// If the given position is out of bounds, `true` is returned.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - location: The position to be checked.
    /// - Returns: Whether the given position is a whitespace.
    private func isWhitespace(_ string: String, _ location: Int) -> Bool {
        guard location > 0,
              location < string.count else { return true }
        
        return string[string.index(string.startIndex, offsetBy: location)].isWhitespace
    }
    
    /// Returns whether the following character is a special character.
    ///
    /// If the position is out of bounds, `true` is returned.
    ///
    /// - Parameters:
    ///   - string: The string in which to check.
    ///   - location: The position to be checked.
    /// - Returns: Whether the following character is a special one.
    private func isSpecial(_ string: String, _ location: Int) -> Bool {
        guard location > 0,
              location < string.count else { return true }
        
        return Tokenizer.isSpecial(string[string.index(string.startIndex, offsetBy: location)])
    }
    
    /// Returns the appropriate closing string for the given string.
    ///
    /// - Parameter opening: The string to be closed.
    /// - Returns: The corresponding closing string.
    private func getClosingString(_ opening: String) -> String {
        let toReturn: String
        
        switch opening {
        case "(": toReturn = ")"
        case "{": toReturn = "}"
        case "[": toReturn = "]"
            
        default:  toReturn = opening
        }
        
        return toReturn
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
        Task { loader.save(file: file!, content: content) }
        lastSaved = content
        window?.isDocumentEdited = false
        setStatus(text: "\(file!) saved.")
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeImpl()
    }
    
    func close() -> Bool {
        if window?.delegate === self {
            window?.performClose(self)
            return window == nil || !window!.isVisible
        } else {
            return closeImpl()
        }
    }
    
    /// Closes the editor.
    private func closeImpl() -> Bool {
        if let window,
           window.isDocumentEdited {
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
                return closeImpl()
                                           
            case .alertSecondButtonReturn:
                window.isDocumentEdited = false
                
            default: return false
            }
        }
        suggestionWindow.close()
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
    
    private func interpretCode() {
        Task {
            let interpreter = Interpreter(loader: loader, referrer: file)
            var parser      = Parser(text: textStorage.string)
            self.ast        = parser.parse()
            self.context    = await interpreter.createContext(for: self.ast, file: self.file)
            self.highlights = interpreter.highlights
            self.editedRange = nil
            
            DispatchQueue.main.async {
                self.textStorage.beginEditing()
                self.textStorage.setAttributes(SPStyle().native, range: NSMakeRange(0, self.textStorage.length))
                self.tokens.forEach {
                    self.textStorage.setAttributes((self.theme.styleFor(type: $0.type) ?? SPStyle()).native, range: NSMakeRange($0.begin, $0.end - $0.begin))
                }
                
                for range in self.highlights {
                    if let style = self.theme.styleFor(type: range.type) {
                        self.textStorage.addAttributes(style.native, range: NSMakeRange(range.begin, range.end - range.begin))
                    }
                }
                self.tokens.forEach {
                    if $0.isType(.COMMENT_LINE, .COMMENT_BLOCK) {
                        self.textStorage.setAttributes((self.theme.styleFor(type: $0.type) ?? SPStyle()).native, range: NSMakeRange($0.begin, $0.end - $0.begin))
                    }
                }
                self.textStorage.endEditing()
                self.updateStatus()
                self.updateSuggestionsImpl(type: nil, returnType: nil)
            }
        }
    }
    
    private func startTimer() {
        interpreterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.interpretCode()
            self.interpreterTimer = nil
        })
    }
    
    /// Performs the highlighting of the text.
    private func highlight(range: (editPosition: Int, delta: Int) = (0, 0)) {
        textStorage.beginEditing()
        textStorage.setAttributes(SPStyle().native, range: NSRange(0 ..< textStorage.length))
        var tokenizer = Tokenizer(stream: StringStream(text: textStorage.string), commentTokens: true)
        
        tokens = []
        var token = tokenizer.nextToken()
        while token.type != .EOF {            
            textStorage.setAttributes((theme.styleFor(type: token.type) ?? SPStyle()).native, range: NSMakeRange(token.begin, token.end - token.begin))
            
            tokens.append(token)
            token = tokenizer.nextToken()
        }
        
        let length = textStorage.length
        highlights.forEach {
            if let style = theme.styleFor(type: $0.type) {
                var start = $0.begin
                if range.editPosition < start {
                    start = start + range.delta
                }
                var end = $0.end
                if range.editPosition < end {
                    end = end + range.delta
                }
                
                end   = end   >= length ? length : end
                start = start >= length ? length : start
                textStorage.addAttributes(style.native, range: NSMakeRange(start, end > start ? end - start
                                                                                              : 0))
            }
        }
        
        textStorage.endEditing()
        interpreterTimer?.invalidate()
        startTimer()
    }
}
