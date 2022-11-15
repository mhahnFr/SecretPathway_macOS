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

struct DialogView: View {
    @ObservedObject var delegate: DialogDelegate
    
    var body: some View {
        VStack {
            Text(delegate.message).bold()
            Text(delegate.addition)
            
            HStack {
                Spacer()
                if let dismissText = delegate.dismissButton {
                    Button(dismissText) { delegate.dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ForEach(delegate.otherButtons, id: \.self) { buttonLabel in
                    Button(buttonLabel) { delegate.action(for: buttonLabel) }
                }
                if let acceptText = delegate.acceptButton {
                    Button(acceptText) { delegate.accept() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }.padding(5)
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView(delegate: DialogDelegate(for: nil))
    }
}
