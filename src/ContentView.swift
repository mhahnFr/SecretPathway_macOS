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

struct ContentView: View {
    @State var userInput: String = ""
    @ObservedObject var connection: ClientConnection
    let font: Font = .system(size: 12, design: .monospaced)
    
    var body: some View {
        VStack {
            ScrollView(content: {
                TextField("", text: $connection.boundText)
                    .font(font)
                    .disabled(true)
            })
            HStack(alignment: .center, spacing: nil, content: {
                Spacer()
                Text(connection.boundPrompt)
                    .font(font)
                TextField("", text: $userInput, onEditingChanged: { _ in return }, onCommit: { sendMessage() })
                .font(font)
                Button("Send", action: {
                    if !userInput.isEmpty {
                        sendMessage()
                    }
                })
                Spacer()
            })
            Spacer()
        }.frame(minWidth: 300, idealWidth: 750, maxWidth: .infinity, minHeight: 200, idealHeight: 500, maxHeight: .infinity, alignment: .center)
    }
    
    func sendMessage() {
        connection.send(string: userInput)
        connection.boundText.append(connection.boundPrompt)
        connection.boundText.append(userInput)
        connection.boundText.append("\n")
        userInput = ""
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(connection: ClientConnection())
    }
}
