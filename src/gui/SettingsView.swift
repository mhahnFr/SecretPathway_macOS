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
 * this program, see the file LICENSE.  If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject var delegate: SettingsViewDelegate
    
    var body: some View {
        VStack {
            HStack {
                Text("The font size:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Stepper(value: settings.$fontSize) {
                    Text("\(settings.fontSize)").bold()
                }
            }
            Toggle("Use inlined editor", isOn: settings.$editorInlined)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Automatically enable syntax highlighting in the editor", isOn: settings.$editorSyntaxHighlighting)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Use UTF-8 by default", isOn: settings.$useUTF8)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Menu(delegate.selectedTheme?.lastPathComponent ?? "Default") {
                    Button("Default") {
                        delegate.useDefaultTheme()
                    }
                    ForEach(delegate.themes, id: \.self) { element in
                        Button(element.lastPathComponent) {
                            delegate.useTheme(element)
                        }
                    }
                    Button("Choose...") {
                        delegate.chooseTheme()
                    }
                }
            }
        }.padding(5)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(delegate: SettingsViewDelegate())
    }
}
