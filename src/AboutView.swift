//
//  AboutView.swift
//  SecretPathway
//
//  Created by Manuel Hahn on 29.10.22.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(content: {
            Text("The SecretPathway").bold()
            Text("Version x.x.x")
            Spacer()
            Text("© Copyright 2022 mhahnFr (https://www.github.com/mhahnFr)")
            Text("Licensed under the terms of the **GPL 3.0**.")
            Text("More informations: https://www.github.com/mhahnFr/SecretPathway_macOS")
        }).padding()
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
