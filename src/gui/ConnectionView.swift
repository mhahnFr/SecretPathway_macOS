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
 * this program, see the file LICENSE. If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI

struct ConnectionView: View {
    @ObservedObject var delegate: ConnectionDelegate
    @ObservedObject var settings = Settings.shared

    @State var enteredText = ""
    
    var body: some View {
        if let delegate = delegate.editorDelegate {
            EditorView(delegate: delegate)
        } else {
            VStack {
                if let message = delegate.message {
                    Text(message)
                        .foregroundColor(delegate.messageColor)
                        .bold()
                }
                NSTextViewBridge(length: delegate.contentLength, fontSize: settings.fontSize, delegate: delegate)
                HStack {
                    if let prompt = delegate.promptString {
                        Text(prompt)
                    }
                    if delegate.showPasswordField {
                        SecureField("Enter something...", text: $enteredText)
                            .font(.system(size: CGFloat(settings.fontSize), design: .monospaced))
                            .onSubmit {
                                sendMessage()
                            }
                    } else {
                        TextField("Enter something...", text: $enteredText)
                            .font(.system(size: CGFloat(settings.fontSize), design: .monospaced))
                            .onSubmit {
                                sendMessage()
                            }
                    }
                    Button("Send") {
                        sendMessage()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(minWidth: 300, idealWidth: 750, minHeight: 200, idealHeight: 500)
            .padding(5)
        }
    }
    
    private func sendMessage() {
        delegate.send(enteredText)
        enteredText = ""
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionView(delegate: ConnectionDelegate(for: Connection(hostname: "localhost", port: 4242, secure: false)!))
    }
}
