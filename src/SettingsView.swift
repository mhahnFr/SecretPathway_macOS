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
import Combine

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State          var portNo   = String(Settings.shared.port)
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, content: {
            Text("Hostname or IP-address: ")
            TextField("Hostname or Ip-address", text: $settings.host)
            Text("Port: ")
            TextField("Port: ", text: $portNo)
                .onReceive(Just(portNo), perform: { newValue in
                    let filtered = newValue.filter { character in "0123456789".contains(character) }
                    if filtered != newValue {
                        portNo = filtered
                        settings.port = Int(filtered)!
                    }
                })
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: Settings.shared)
    }
}
