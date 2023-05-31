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
import SwiftUI

/// This structure bridges a NSTextView from the AppKit into SwiftUI.
struct NSTextViewBridge: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    
    /// The length of the content text used as trigger.
    var length: Int
    /// The font size that should be used by this view.
    var fontSize: Double
    /// An optional delegate that can provide additional functionality.
    weak var delegate: TextViewBridgeDelegate?
    
    func makeNSView(context: Self.Context) -> NSViewType {
        let toReturn = KeyHookTextView.scrollableTextView()
        let textView = toReturn.documentView as! KeyHookTextView
        
        textView.layoutManager?.allowsNonContiguousLayout = false
        textView.isHorizontallyResizable                  = true
        textView.isVerticallyResizable                    = true

        delegate?.initTextView(textView)
        
        return toReturn
    }
    
    func updateNSView(_ nsView: NSViewType, context: Self.Context) {
        let textView = nsView.documentView as! NSTextView
        
        delegate?.updateTextView(textView)
    }
}
