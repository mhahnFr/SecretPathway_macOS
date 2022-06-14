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
    
    var body: some View {
        VStack {
            Text(connection.boundText)
                .fixedSize(horizontal: false, vertical: false)
                .frame(minWidth: 300, idealWidth: 750, maxWidth: .infinity, minHeight: 200, idealHeight: 500, maxHeight: .infinity, alignment: .topLeading)
//                .disabled(true)
            HStack(alignment: .center, spacing: nil, content: {
                Text(connection.boundPrompt)
                TextField("", text: $userInput)
                Button("Send") {
                    connection.send(string: userInput)
                }
            })
        }
    }
}


/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/
