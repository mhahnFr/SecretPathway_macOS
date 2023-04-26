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

import SwiftUI

struct EditorView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var delegate: EditorDelegate
    
    var body: some View {
        VStack {
            NSTextViewBridge(length: 0, fontSize: settings.fontSize, delegate: delegate)
            VStack {
                Text(delegate.statusText).frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Toggle("Syntax Highlighting", isOn: $delegate.syntaxHighlighting).frame(maxWidth: .infinity, alignment: .leading)
                    Button("Close") {
                        delegate.close()
                    }.keyboardShortcut(.cancelAction)
                    Button("Save") {
                        delegate.saveText()
                    }.keyboardShortcut(.return, modifiers: .command)
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }.padding(5)
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(delegate: EditorDelegate(loader: LocalFileManager()))
    }
}
