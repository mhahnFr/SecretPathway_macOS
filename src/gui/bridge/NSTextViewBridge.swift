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
import SwiftUI

struct NSTextViewBridge: NSViewRepresentable {
    var text: String
    var fontSize: Double
    
    func makeNSView(context: Context) -> some NSView {
        let toReturn = NSTextView.scrollableTextView()
        let textView = toReturn.documentView as! NSTextView
        textView.isEditable = false
        return toReturn
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let textView = (nsView as! NSScrollView).documentView as! NSTextView
        
        textView.textStorage?.setAttributedString(NSAttributedString(string: text))
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = .textColor
        textView.scrollRangeToVisible(NSMakeRange(textView.string.count, 0))
    }
}
