//
//  ContentView.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 4/21/22.
//

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
                Text(connection.boundPrompt)
                    .font(font)
                TextField("", text: $userInput, onEditingChanged: { _ in return }, onCommit: {
                    connection.send(string: userInput)
                    connection.boundText.append(connection.boundPrompt)
                    connection.boundText.append(userInput)
                    connection.boundText.append("\n")
                    userInput = ""
                })
                .font(font)
            })
        }.frame(minWidth: 300, idealWidth: 750, maxWidth: .infinity, minHeight: 200, idealHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(connection: ClientConnection())
    }
}
