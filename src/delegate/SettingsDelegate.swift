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

import AppKit

/// The delegate for the settings window.
class SettingsViewDelegate: NSObject, NSWindowDelegate, ObservableObject {
    @Published private(set) var selectedTheme: URL?
    @Published private(set) var themes: [URL] = []
    
    private var chooser: NSOpenPanel?
    
    override init() {
        if let url  = Settings.shared.editorTheme,
           let data = try? Data(contentsOf: url),
           let _    = try? JSONDecoder().decode(JSONTheme.self, from: data) {
            self.selectedTheme = url
            self.themes        = [url]
        } else {
            self.selectedTheme = nil
        }
    }
    
    func useDefaultTheme() {
        selectedTheme = nil
    }
    
    func chooseTheme() {
        guard chooser == nil else {
            chooser!.makeKeyAndOrderFront(self)
            return
        }
        
        chooser = NSOpenPanel()
        chooser!.allowsMultipleSelection = false
        chooser!.canChooseDirectories    = false
        chooser!.canCreateDirectories    = false
        chooser!.canChooseFiles          = true
        chooser!.begin { response in
            guard response == .OK, let url = self.chooser?.url else { return }
            
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: url)
                _ = try decoder.decode(JSONTheme.self, from: data)
            } catch {
                // TODO: Implement
                return
            }
            
            self.themes.append(url)
            self.selectedTheme = url
        }
    }
    
    func useTheme(_ theme: URL) {
        selectedTheme = theme
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        chooser?.performClose(self)
        if Settings.shared.editorTheme != selectedTheme {
            Settings.shared.editorTheme = selectedTheme
        }
        return true
    }
}
