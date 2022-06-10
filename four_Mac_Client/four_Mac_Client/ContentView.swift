//
//  ContentView.swift
//  four_Mac_Client
//
//  Created by Manuel Hahn on 4/21/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
