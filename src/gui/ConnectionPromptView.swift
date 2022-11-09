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

import SwiftUI

struct ConnectionPromptView: View {
    @ObservedObject var delegate: ConnectionPromptDelegate
    
    var body: some View {
        VStack {
            if let userInfo = delegate.userInfo {
                Text(userInfo).foregroundColor(.red)
                Spacer()
            }
            VStack(alignment: .leading) {
                Text("Enter the hostname or the IP address:")
                if #available(macOS 12.0, *) {
                    TextField("hostname or IP address, ex: localhost", text: $delegate.hostname).onSubmit {
                        delegate.accept()
                    }
                } else {
                    TextField("hostname or IP address, ex: localhost", text: $delegate.hostname)
                }
            }
            VStack(alignment: .leading) {
                Text("Enter the port number:")
                if #available(macOS 12.0, *) {
                    TextField("port number, ex: 4242", text: $delegate.port).onSubmit {
                        delegate.accept()
                    }
                } else {
                    TextField("port number, ex: 4242", text: $delegate.port)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") {
                    delegate.dismiss()
                }.keyboardShortcut(.cancelAction)
                Button("OK") {
                    delegate.accept()
                }.keyboardShortcut(.defaultAction)
            }
        }.padding(5)
    }
}

struct ConnectionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionPromptView(delegate: ConnectionPromptDelegate(with: nil))
    }
}
